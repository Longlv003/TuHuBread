const { userModel } = require("../models/user.model");
const notificationService = require("../services/notification.service");

async function findCurrentUser(req) {
  if (!req.user || !req.user.uid) return null;
  return userModel.findOne({ firebase_uid: req.user.uid, deleted_at: null });
}

// GET /api/notifications
exports.getNotifications = async (req, res) => {
  const dataRes = { msg: "OK", data: null };
  try {
    const user = await findCurrentUser(req);
    if (!user) {
      dataRes.msg = "Unauthorized - User not found";
      return res.status(401).json(dataRes);
    }

    const page = parseInt(req.query.page) || 1;
    const result = await notificationService.getNotificationsForUser(user._id, page);
    dataRes.msg = "Notifications retrieved successfully";
    dataRes.data = {
      notifications: result.notifications,
      pagination: {
        page: result.page,
        limit: 20,
        total: result.total,
        totalPages: result.totalPages,
      },
    };
    return res.status(200).json(dataRes);
  } catch (err) {
    console.error("[NotificationController] Failed to retrieve notifications:", err.message);
    dataRes.msg = "Server error: " + err.message;
    return res.status(500).json(dataRes);
  }
};

// GET /api/notifications/unread-count
exports.getUnreadCount = async (req, res) => {
  const dataRes = { msg: "OK", data: null };
  try {
    const user = await findCurrentUser(req);
    if (!user) {
      dataRes.msg = "Unauthorized - User not found";
      return res.status(401).json(dataRes);
    }

    const count = await notificationService.getUnreadCount(user._id);
    dataRes.msg = "Unread notification count retrieved successfully";
    dataRes.data = { count };
    return res.status(200).json(dataRes);
  } catch (err) {
    console.error("[NotificationController] Failed to get unread count:", err.message);
    dataRes.msg = "Server error: " + err.message;
    return res.status(500).json(dataRes);
  }
};

// PATCH /api/notifications/:notificationId/read
exports.markAsRead = async (req, res) => {
  const dataRes = { msg: "OK", data: null };
  try {
    const user = await findCurrentUser(req);
    if (!user) {
      dataRes.msg = "Unauthorized - User not found";
      return res.status(401).json(dataRes);
    }

    const { notificationId } = req.params;
    if (!notificationId) {
      dataRes.msg = "Missing notificationId parameter";
      return res.status(400).json(dataRes);
    }

    const notification = await notificationService.markAsRead(user._id, notificationId);
    dataRes.msg = "Notification marked as read successfully";
    dataRes.data = notification;
    return res.status(200).json(dataRes);
  } catch (err) {
    console.error("[NotificationController] Failed to mark notification as read:", err.message);
    dataRes.msg = err.message || "Server error";
    return res.status(400).json(dataRes);
  }
};

// PATCH /api/notifications/read-all
exports.markAllAsRead = async (req, res) => {
  const dataRes = { msg: "OK", data: null };
  try {
    const user = await findCurrentUser(req);
    if (!user) {
      dataRes.msg = "Unauthorized - User not found";
      return res.status(401).json(dataRes);
    }

    await notificationService.markAllAsRead(user._id);
    dataRes.msg = "All notifications marked as read successfully";
    dataRes.data = null;
    return res.status(200).json(dataRes);
  } catch (err) {
    console.error("[NotificationController] Failed to mark all notifications as read:", err.message);
    dataRes.msg = "Server error: " + err.message;
    return res.status(500).json(dataRes);
  }
};

// POST /api/notifications/device-token
exports.registerDeviceToken = async (req, res) => {
  const dataRes = { msg: "OK", data: null };
  try {
    const user = await findCurrentUser(req);
    if (!user) {
      dataRes.msg = "Unauthorized - User not found";
      return res.status(401).json(dataRes);
    }

    const { token, platform } = req.body;
    if (!token || !platform) {
      dataRes.msg = "Missing token or platform in request body";
      return res.status(400).json(dataRes);
    }

    const device = await notificationService.registerDevice(user._id, {
      fcmToken: token,
      platform,
    });
    dataRes.msg = "Device token registered successfully";
    dataRes.data = device;
    return res.status(200).json(dataRes);
  } catch (err) {
    console.error("[NotificationController] Failed to register device token:", err.message);
    dataRes.msg = err.message || "Server error";
    return res.status(400).json(dataRes);
  }
};

// DELETE /api/notifications/device-token
exports.deactivateDeviceToken = async (req, res) => {
  const dataRes = { msg: "OK", data: null };
  try {
    const user = await findCurrentUser(req);
    if (!user) {
      dataRes.msg = "Unauthorized - User not found";
      return res.status(401).json(dataRes);
    }

    const { token } = req.body;
    if (!token) {
      dataRes.msg = "Missing token in request body";
      return res.status(400).json(dataRes);
    }

    await notificationService.unregisterDevice(token);
    dataRes.msg = "Device token deactivated successfully";
    dataRes.data = null;
    return res.status(200).json(dataRes);
  } catch (err) {
    console.error("[NotificationController] Failed to deactivate device token:", err.message);
    dataRes.msg = err.message || "Server error";
    return res.status(400).json(dataRes);
  }
};
