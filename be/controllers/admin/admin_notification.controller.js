const notificationService = require("../../services/notification.service");

class AdminNotificationController {
  async showNotifications(req, res) {
    try {
      const page = parseInt(req.query.page) || 1;
      const result = await notificationService.getNotifications(page);

      res.render("admin/notifications", {
        ...result,
        admin: req.admin,
        title: "Quản lý Thông báo",
        activeTab: "notifications"
      });
    } catch (err) {
      console.error("Show notifications controller error:", err.message);
      res.status(500).render("error", {
        message: "Failed to load notifications: " + err.message,
        error: err
      });
    }
  }

  async createNotification(req, res) {
    try {
      const result = await notificationService.createAndSend(req.body);
      return res.json({
        status: "success",
        msg: `Đã tạo và gửi thông báo tới ${result.recipientCount} người dùng (${result.successCount} push thành công, ${result.failureCount} thất bại).`,
        data: result
      });
    } catch (err) {
      console.error("Create notification controller error:", err.message);
      return res.status(400).json({ status: "error", msg: err.message });
    }
  }
}

module.exports = new AdminNotificationController();
