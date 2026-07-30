const notificationService = require("../../services/notification.service");

function buildFirebaseConfig() {
  return {
    apiKey: process.env.FIREBASE_API_KEY,
    authDomain: process.env.FIREBASE_AUTH_DOMAIN,
    projectId: process.env.FIREBASE_PROJECT_ID,
    storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
    messagingSenderId: process.env.FIREBASE_MESSAGING_SENDER_ID,
    appId: process.env.FIREBASE_APP_ID
  };
}

class ShopNotificationController {
  async showNotifications(req, res) {
    try {
      const result = await notificationService.getNotificationsSentByShop(req.shop._id, req.query.page);

      res.render("shop/notifications", {
        ...result,
        firebaseConfig: buildFirebaseConfig(),
        shop: req.shop,
        user: req.user,
        title: "Quản lý Thông báo",
        activeTab: "notifications"
      });
    } catch (err) {
      console.error("Show shop notifications controller error:", err.message);
      res.status(500).render("error", {
        message: "Failed to load notifications: " + err.message,
        error: err
      });
    }
  }

  async createNotification(req, res) {
    try {
      const result = await notificationService.createAndSendFromShop(req.shop._id, req.body);
      return res.json({
        status: "success",
        msg: `Đã tạo và gửi thông báo tới ${result.recipientCount} người dùng (${result.successCount} push thành công, ${result.failureCount} thất bại).`,
        data: result
      });
    } catch (err) {
      console.error("Create shop notification controller error:", err.message);
      return res.status(400).json({ status: "error", msg: err.message });
    }
  }
}

module.exports = new ShopNotificationController();
