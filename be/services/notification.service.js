const mongoose = require("mongoose");
const { messaging } = require("../configs/firebase.config");
const { notificationModel } = require("../models/notification.model");
const { userDeviceModel } = require("../models/userDevice.model");
const notificationRepository = require("../repositories/notification.repository");
const userDeviceRepository = require("../repositories/userDevice.repository");
const accountRepository = require("../repositories/account.repository");
const { userModel } = require("../models/user.model");
const fcmService = require("./fcm.service");
const { NOTIFICATION_TYPES, SOCKET_EVENTS } = require("../constants/notification.constants");

const FCM_BATCH_SIZE = 500;

async function sendPushInBatches(tokens, title, body) {
  if (!tokens.length) return { successCount: 0, failureCount: 0 };

  let successCount = 0;
  let failureCount = 0;

  for (let i = 0; i < tokens.length; i += FCM_BATCH_SIZE) {
    const batch = tokens.slice(i, i + FCM_BATCH_SIZE);
    try {
      const response = await messaging.sendEachForMulticast({
        tokens: batch,
        notification: { title, body }
      });
      successCount += response.successCount;
      failureCount += response.failureCount;
    } catch (err) {
      console.error("FCM send batch failed:", err.message);
      failureCount += batch.length;
    }
  }

  return { successCount, failureCount };
}

class NotificationService {
  async getNotifications(page = 1) {
    const [notifications, total] = await Promise.all([
      notificationRepository.findAllPaginated(page, 20),
      notificationRepository.countAll()
    ]);
    return { notifications, total, page, totalPages: Math.max(Math.ceil(total / 20), 1) };
  }

  async createAndSend({ title, body, type, target, userEmail }) {
    if (!title || !body || !type) {
      throw new Error("Tiêu đề, nội dung và loại thông báo là bắt buộc");
    }
    if (!["order", "voucher", "system"].includes(type)) {
      throw new Error("Loại thông báo không hợp lệ");
    }

    if (target === "user") {
      if (!userEmail) {
        throw new Error("Vui lòng nhập email người dùng cần gửi");
      }
      const user = await accountRepository.findByEmail(userEmail.trim());
      if (!user) {
        throw new Error("Không tìm thấy người dùng với email này");
      }

      await notificationRepository.create({
        user_id: user._id, title, body, type, sent_at: new Date()
      });

      const tokens = await userDeviceRepository.findActiveTokensByUserId(user._id);
      const pushResult = await sendPushInBatches(tokens, title, body);
      return { recipientCount: 1, ...pushResult };
    }

    // target === "all": broadcast to every customer
    const customers = await userModel.find({ role: "customer", deleted_at: null }).select("_id");
    if (customers.length > 0) {
      const docs = customers.map(c => ({
        user_id: c._id, title, body, type, sent_at: new Date()
      }));
      await notificationRepository.insertMany(docs);
    }

    const tokens = await userDeviceRepository.findAllActiveTokens();
    const pushResult = await sendPushInBatches(tokens, title, body);
    return { recipientCount: customers.length, ...pushResult };
  }

  /**
   * Main notification orchestrator
   * @param {Object} params
   * @param {string|mongoose.Types.ObjectId} params.userId - Target user ID
   * @param {string} params.type - One of NOTIFICATION_TYPES
   * @param {string} params.title - Notification title
   * @param {string} params.message - Notification body
   * @param {Object} [params.data] - Extra payload data
   * @param {string|mongoose.Types.ObjectId} [params.orderId] - Associated Order ID
   * @returns {Promise<Object>} The saved notification document
   */
  async notify({ userId, type, title, message, data = {}, orderId }) {
    // 1. Validate Input
    if (!userId) {
      throw new Error("[NotificationService] Missing target userId");
    }
    if (!type || !NOTIFICATION_TYPES[type]) {
      throw new Error(`[NotificationService] Invalid or missing notification type: ${type}`);
    }
    if (!title || !message) {
      throw new Error("[NotificationService] Title and message are required");
    }

    // 2. Prepare and save notification document to MongoDB
    const notificationPayload = {
      user_id: userId,
      title,
      body: message,
      type,
      data: {
        ...data,
        notificationId: "", // Will update after save or just place orderId
        orderId: orderId ? orderId.toString() : (data.orderId || ""),
        type,
      },
      is_read: false,
      sent_at: new Date(),
    };

    let savedNotification;
    try {
      savedNotification = await notificationModel.create(notificationPayload);
      // Append notification ID to payload data for Socket & FCM
      savedNotification.data = {
        ...savedNotification.data,
        notificationId: savedNotification._id.toString(),
      };
      await savedNotification.save();
    } catch (dbError) {
      console.error("[NotificationService] Database save failed:", dbError.message);
      throw dbError; // DB error is critical
    }

    // 3. Emit via Socket.IO
    try {
      const { getIo } = require("../sockets/socket.module");
      const io = getIo();
      if (io) {
        const roomName = `user:${userId}`;
        io.to(roomName).emit(SOCKET_EVENTS.NOTIFICATION_NEW, savedNotification);
        
        // Also emit count update
        const unreadCount = await notificationModel.countDocuments({
          user_id: userId,
          is_read: false,
          deleted_at: null,
        });
        io.to(roomName).emit(SOCKET_EVENTS.NOTIFICATION_COUNT_UPDATED, { count: unreadCount });
        console.log(`[SocketService] Emitted notification to ${roomName}`);
      }
    } catch (socketError) {
      console.warn("[SocketService] Failed to emit notification via Socket.IO:", socketError.message);
    }

    // 4. Get active FCM device tokens
    let activeDevices = [];
    try {
      activeDevices = await userDeviceModel.find({
        user_id: userId,
        is_active: true,
        deleted_at: null,
      });
    } catch (deviceError) {
      console.warn("[NotificationService] Failed to retrieve user devices:", deviceError.message);
    }

    // 5. Send FCM Notifications
    if (activeDevices.length > 0) {
      const tokens = activeDevices.map(d => d.fcm_token);
      
      // Async call so it doesn't block response, but we handle results safely
      fcmService.sendToMultipleTokens({
        tokens,
        notification: { title, body: message },
        data: savedNotification.data,
      }).then(async (result) => {
        console.log(`[NotificationService] FCM Send results: Success=${result.successCount}, Failures=${result.failureCount}`);
        
        // 6. Deactivate invalid/expired tokens returned from FCM service
        if (result.invalidTokens && result.invalidTokens.length > 0) {
          try {
            const updateResult = await userDeviceModel.updateMany(
              { fcm_token: { $in: result.invalidTokens } },
              { $set: { is_active: false } }
            );
            console.log(`[NotificationService] Deactivated ${updateResult.modifiedCount} invalid FCM tokens`);
          } catch (deactivateError) {
            console.error("[NotificationService] Failed to deactivate invalid FCM tokens in DB:", deactivateError.message);
          }
        }
      }).catch((fcmPromiseError) => {
        console.error("[NotificationService] FCM async processing encountered error:", fcmPromiseError.message);
      });
    } else {
      console.log(`[NotificationService] No active FCM devices found for user: ${userId}`);
    }

    return savedNotification;
  }
}

module.exports = new NotificationService();
