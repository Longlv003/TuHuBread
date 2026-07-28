const { messaging } = require("../configs/firebase.config");
const notificationRepository = require("../repositories/notification.repository");
const userDeviceRepository = require("../repositories/userDevice.repository");
const accountRepository = require("../repositories/account.repository");
const { userModel } = require("../models/user.model");

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
}

module.exports = new NotificationService();
