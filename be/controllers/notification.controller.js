const { userModel } = require("../models/user.model");
const notificationService = require("../services/notification.service");

async function findCurrentUser(req) {
  return userModel.findOne({ firebase_uid: req.user.uid });
}

// GET /api/notifications
exports.getMyNotifications = async (req, res) => {
  const dataRes = { status: "error", msg: "" };
  try {
    const user = await findCurrentUser(req);
    if (!user) {
      dataRes.msg = "Không tìm thấy user";
      return res.status(404).json(dataRes);
    }

    const result = await notificationService.getNotificationsForUser(user._id, req.query.page);
    dataRes.status = "success";
    dataRes.data = result;
    return res.json(dataRes);
  } catch (err) {
    console.error("Get my notifications error:", err.message);
    dataRes.msg = "Server error: " + err.message;
    return res.status(500).json(dataRes);
  }
};

// GET /api/notifications/unread-count
exports.getUnreadCount = async (req, res) => {
  const dataRes = { status: "error", msg: "" };
  try {
    const user = await findCurrentUser(req);
    if (!user) {
      dataRes.msg = "Không tìm thấy user";
      return res.status(404).json(dataRes);
    }

    const count = await notificationService.getUnreadCount(user._id);
    dataRes.status = "success";
    dataRes.data = { count };
    return res.json(dataRes);
  } catch (err) {
    console.error("Get unread count error:", err.message);
    dataRes.msg = "Server error: " + err.message;
    return res.status(500).json(dataRes);
  }
};

// PUT /api/notifications/:id/read
exports.markAsRead = async (req, res) => {
  const dataRes = { status: "error", msg: "" };
  try {
    const user = await findCurrentUser(req);
    if (!user) {
      dataRes.msg = "Không tìm thấy user";
      return res.status(404).json(dataRes);
    }

    const notification = await notificationService.markAsRead(user._id, req.params.id);
    dataRes.status = "success";
    dataRes.data = notification;
    return res.json(dataRes);
  } catch (err) {
    console.error("Mark notification as read error:", err.message);
    dataRes.msg = err.message || "Server error";
    return res.status(400).json(dataRes);
  }
};

// PUT /api/notifications/read-all
exports.markAllAsRead = async (req, res) => {
  const dataRes = { status: "error", msg: "" };
  try {
    const user = await findCurrentUser(req);
    if (!user) {
      dataRes.msg = "Không tìm thấy user";
      return res.status(404).json(dataRes);
    }

    await notificationService.markAllAsRead(user._id);
    dataRes.status = "success";
    dataRes.data = { success: true };
    return res.json(dataRes);
  } catch (err) {
    console.error("Mark all notifications as read error:", err.message);
    dataRes.msg = "Server error: " + err.message;
    return res.status(500).json(dataRes);
  }
};

// DELETE /api/notifications/:id
exports.deleteNotification = async (req, res) => {
  const dataRes = { status: "error", msg: "" };
  try {
    const user = await findCurrentUser(req);
    if (!user) {
      dataRes.msg = "Không tìm thấy user";
      return res.status(404).json(dataRes);
    }

    await notificationService.deleteNotification(user._id, req.params.id);
    dataRes.status = "success";
    dataRes.data = { success: true };
    return res.json(dataRes);
  } catch (err) {
    console.error("Delete notification error:", err.message);
    dataRes.msg = err.message || "Server error";
    return res.status(400).json(dataRes);
  }
};

// DELETE /api/notifications
exports.deleteAllNotifications = async (req, res) => {
  const dataRes = { status: "error", msg: "" };
  try {
    const user = await findCurrentUser(req);
    if (!user) {
      dataRes.msg = "Không tìm thấy user";
      return res.status(404).json(dataRes);
    }

    await notificationService.deleteAllNotifications(user._id);
    dataRes.status = "success";
    dataRes.data = { success: true };
    return res.json(dataRes);
  } catch (err) {
    console.error("Delete all notifications error:", err.message);
    dataRes.msg = "Server error: " + err.message;
    return res.status(500).json(dataRes);
  }
};

// POST /api/devices/register
exports.registerDevice = async (req, res) => {
  const dataRes = { status: "error", msg: "" };
  try {
    const user = await findCurrentUser(req);
    if (!user) {
      dataRes.msg = "Không tìm thấy user";
      return res.status(404).json(dataRes);
    }

    const { fcm_token, platform, device_id, device_name } = req.body;
    const device = await notificationService.registerDevice(user._id, {
      fcmToken: fcm_token,
      platform,
      deviceId: device_id,
      deviceName: device_name,
    });
    dataRes.status = "success";
    dataRes.data = device;
    return res.json(dataRes);
  } catch (err) {
    console.error("Register device error:", err.message);
    dataRes.msg = err.message || "Server error";
    return res.status(400).json(dataRes);
  }
};

// POST /api/devices/unregister
exports.unregisterDevice = async (req, res) => {
  const dataRes = { status: "error", msg: "" };
  try {
    const { fcm_token } = req.body;
    await notificationService.unregisterDevice(fcm_token);
    dataRes.status = "success";
    dataRes.data = { success: true };
    return res.json(dataRes);
  } catch (err) {
    console.error("Unregister device error:", err.message);
    dataRes.msg = err.message || "Server error";
    return res.status(400).json(dataRes);
  }
};
