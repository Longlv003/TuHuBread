const { messaging } = require("../configs/firebase.config");
const notificationRepository = require("../repositories/notification.repository");
const userDeviceRepository = require("../repositories/userDevice.repository");
const { userModel } = require("../models/user.model");
const { orderModel } = require("../models/order.model");

const CUSTOMER_PAGE_SIZE = 20;

const FCM_BATCH_SIZE = 500;

async function sendPushInBatches(tokens, title, body, data) {
  if (!tokens.length) return { successCount: 0, failureCount: 0 };

  // FCM data payload chỉ chấp nhận string cho mọi giá trị.
  const stringData = data
    ? Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)]))
    : undefined;

  let successCount = 0;
  let failureCount = 0;

  for (let i = 0; i < tokens.length; i += FCM_BATCH_SIZE) {
    const batch = tokens.slice(i, i + FCM_BATCH_SIZE);
    try {
      const response = await messaging.sendEachForMulticast({
        tokens: batch,
        notification: { title, body },
        ...(stringData ? { data: stringData } : {}),
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
      notificationRepository.findAllPaginated(page, 10),
      notificationRepository.countAll()
    ]);
    return { notifications, total, page, totalPages: Math.max(Math.ceil(total / 10), 1) };
  }

  async getNotificationsSentByShop(shopId, page = 1) {
    const parsedPage = Math.max(parseInt(page) || 1, 1);
    const limit = 10;
    const [notifications, total] = await Promise.all([
      notificationRepository.findByShopSenderPaginated(shopId, { page: parsedPage, limit }),
      notificationRepository.countByShopSender(shopId),
    ]);
    return { notifications, total, page: parsedPage, totalPages: Math.max(Math.ceil(total / limit), 1) };
  }

  async createAndSendFromShop(shopId, { title, body, type }) {
    // Shop chỉ được gửi cho khách hàng đã mua tại shop của mình — không
    // được broadcast toàn sàn (đó là quyền riêng của Admin).
    return this.createAndSend({
      title, body, type,
      target: "shop_customers",
      shopId,
      senderType: "shop",
      senderShopId: shopId,
    });
  }

  // --- Customer-facing (app) ---

  async getNotificationsForUser(userId, page = 1) {
    const parsedPage = Math.max(parseInt(page) || 1, 1);
    const [notifications, total, unreadCount, unreadByType] = await Promise.all([
      notificationRepository.findByUserIdPaginated(userId, { page: parsedPage, limit: CUSTOMER_PAGE_SIZE }),
      notificationRepository.countByUserId(userId),
      notificationRepository.countUnreadByUserId(userId),
      notificationRepository.countUnreadByUserIdGroupedByType(userId),
    ]);
    return {
      notifications,
      total,
      unreadCount,
      unreadByType,
      page: parsedPage,
      totalPages: Math.max(Math.ceil(total / CUSTOMER_PAGE_SIZE), 1),
    };
  }

  async getUnreadCount(userId) {
    return notificationRepository.countUnreadByUserId(userId);
  }

  async markAsRead(userId, notificationId) {
    const notification = await notificationRepository.findByIdScoped(notificationId, userId);
    if (!notification) {
      throw new Error("Không tìm thấy thông báo");
    }
    return notificationRepository.markRead(notificationId);
  }

  async deleteNotification(userId, notificationId) {
    const notification = await notificationRepository.findByIdScoped(notificationId, userId);
    if (!notification) {
      throw new Error("Không tìm thấy thông báo");
    }
    return notificationRepository.softDeleteScoped(notificationId, userId);
  }

  async deleteAllNotifications(userId) {
    return notificationRepository.softDeleteAllForUser(userId);
  }

  async markAllAsRead(userId) {
    return notificationRepository.markAllReadForUser(userId);
  }

  async registerDevice(userId, { fcmToken, platform, deviceId, deviceName }) {
    if (!fcmToken || !platform) {
      throw new Error("Thiếu fcm_token hoặc platform");
    }
    if (!["android", "ios", "web"].includes(platform)) {
      throw new Error("Platform không hợp lệ");
    }
    return userDeviceRepository.upsertToken({ userId, fcmToken, platform, deviceId, deviceName });
  }

  async unregisterDevice(fcmToken) {
    if (!fcmToken) {
      throw new Error("Thiếu fcm_token");
    }
    return userDeviceRepository.deactivateToken(fcmToken);
  }

  /**
   * Tạo + đẩy push cho đúng 1 user — dùng nội bộ khi có sự kiện thật xảy ra
   * (đơn hàng đổi trạng thái, huỷ đơn...), khác với createAndSend() vốn dành
   * cho Admin chủ động soạn & gửi thủ công.
   * @param {string} userId
   * @param {{title: string, body: string, type: "order"|"voucher"|"system", data?: object}} params
   */
  async notifyUser(userId, { title, body, type, data }) {
    try {
      await notificationRepository.create({
        user_id: userId, title, body, type, data: data || null, sent_at: new Date(), sender_type: "system",
      });
      const tokens = await userDeviceRepository.findActiveTokensByUserId(userId);
      await sendPushInBatches(tokens, title, body, data);
    } catch (err) {
      // Thông báo là tác vụ phụ — không để lỗi gửi thông báo làm hỏng luồng
      // chính (cập nhật đơn hàng...).
      console.error("notifyUser failed:", err.message);
    }
  }

  /**
   * @param {Object} params
   * @param {"all"|"shop_customers"} params.target
   * @param {string} [params.shopId] — bắt buộc khi target === "shop_customers"
   * @param {"admin"|"shop"|"system"} [params.senderType]
   * @param {string|null} [params.senderShopId]
   */
  async createAndSend({ title, body, type, target, shopId, senderType = "admin", senderShopId = null }) {
    if (!title || !body || !type) {
      throw new Error("Tiêu đề, nội dung và loại thông báo là bắt buộc");
    }
    if (!["order", "voucher", "system"].includes(type)) {
      throw new Error("Loại thông báo không hợp lệ");
    }

    const baseDoc = { title, body, type, sent_at: new Date(), sender_type: senderType, sender_shop_id: senderShopId };

    let customerIds;
    if (target === "shop_customers") {
      if (!shopId) {
        throw new Error("Thiếu shop_id để gửi thông báo cho khách hàng của shop");
      }
      customerIds = await orderModel.distinct("user_id", { shop_id: shopId, deleted_at: null });
    } else {
      // target === "all": broadcast to every customer
      const customers = await userModel.find({ role: "customer", deleted_at: null }).select("_id");
      customerIds = customers.map((c) => c._id);
    }

    if (customerIds.length > 0) {
      const docs = customerIds.map((id) => ({ ...baseDoc, user_id: id }));
      await notificationRepository.insertMany(docs);
    }

    const tokens = target === "shop_customers"
      ? (await Promise.all(customerIds.map((id) => userDeviceRepository.findActiveTokensByUserId(id)))).flat()
      : await userDeviceRepository.findAllActiveTokens();
    const pushResult = await sendPushInBatches(tokens, title, body);
    return { recipientCount: customerIds.length, ...pushResult };
  }
}

module.exports = new NotificationService();
