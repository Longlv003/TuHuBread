/**
 * Notification Controller
 * Handles all notification-related API endpoints.
 */

const { notificationModel } = require("../models/notification.model");
const { userDeviceModel } = require("../models/userDevice.model");
const { userModel } = require("../models/user.model");

/**
 * Helper to resolve the MongoDB User from Firebase Auth Token UID.
 * @param {import('express').Request} req 
 * @returns {Promise<Object|null>}
 */
async function resolveUser(req) {
  if (!req.user || !req.user.uid) return null;
  return userModel.findOne({ firebase_uid: req.user.uid, deleted_at: null });
}

/**
 * GET /api/notifications
 * Get paginated notifications for the current user.
 */
exports.getNotifications = async (req, res) => {
  const dataRes = { msg: "OK", data: null };
  try {
    const user = await resolveUser(req);
    if (!user) {
      dataRes.msg = "Unauthorized - User not found";
      return res.status(401).json(dataRes);
    }

    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    const query = { user_id: user._id, deleted_at: null };

    const notifications = await notificationModel.find(query)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    const total = await notificationModel.countDocuments(query);
    const totalPages = Math.ceil(total / limit);

    dataRes.msg = "Notifications retrieved successfully";
    dataRes.data = {
      notifications,
      pagination: {
        page,
        limit,
        total,
        totalPages,
      },
    };
    return res.status(200).json(dataRes);
  } catch (error) {
    console.error("[NotificationController] Failed to retrieve notifications:", error.message);
    dataRes.msg = "Server error: " + error.message;
    return res.status(500).json(dataRes);
  }
};

/**
 * GET /api/notifications/unread-count
 * Get count of unread notifications for the current user.
 */
exports.getUnreadCount = async (req, res) => {
  const dataRes = { msg: "OK", data: null };
  try {
    const user = await resolveUser(req);
    if (!user) {
      dataRes.msg = "Unauthorized - User not found";
      return res.status(401).json(dataRes);
    }

    const count = await notificationModel.countDocuments({
      user_id: user._id,
      is_read: false,
      deleted_at: null,
    });

    dataRes.msg = "Unread notification count retrieved successfully";
    dataRes.data = { count };
    return res.status(200).json(dataRes);
  } catch (error) {
    console.error("[NotificationController] Failed to get unread count:", error.message);
    dataRes.msg = "Server error: " + error.message;
    return res.status(500).json(dataRes);
  }
};

/**
 * PATCH /api/notifications/:notificationId/read
 * Mark a single notification as read.
 */
exports.markAsRead = async (req, res) => {
  const dataRes = { msg: "OK", data: null };
  try {
    const user = await resolveUser(req);
    if (!user) {
      dataRes.msg = "Unauthorized - User not found";
      return res.status(401).json(dataRes);
    }

    const { notificationId } = req.params;
    if (!notificationId) {
      dataRes.msg = "Missing notificationId parameter";
      return res.status(400).json(dataRes);
    }

    const notification = await notificationModel.findOne({
      _id: notificationId,
      user_id: user._id,
      deleted_at: null,
    });

    if (!notification) {
      dataRes.msg = "Notification not found";
      return res.status(404).json(dataRes);
    }

    notification.is_read = true;
    await notification.save();

    dataRes.msg = "Notification marked as read successfully";
    dataRes.data = notification;
    return res.status(200).json(dataRes);
  } catch (error) {
    console.error("[NotificationController] Failed to mark notification as read:", error.message);
    dataRes.msg = "Server error: " + error.message;
    return res.status(500).json(dataRes);
  }
};

/**
 * PATCH /api/notifications/read-all
 * Mark all notifications for current user as read.
 */
exports.markAllAsRead = async (req, res) => {
  const dataRes = { msg: "OK", data: null };
  try {
    const user = await resolveUser(req);
    if (!user) {
      dataRes.msg = "Unauthorized - User not found";
      return res.status(401).json(dataRes);
    }

    await notificationModel.updateMany(
      { user_id: user._id, is_read: false, deleted_at: null },
      { $set: { is_read: true } }
    );

    dataRes.msg = "All notifications marked as read successfully";
    dataRes.data = null;
    return res.status(200).json(dataRes);
  } catch (error) {
    console.error("[NotificationController] Failed to mark all notifications as read:", error.message);
    dataRes.msg = "Server error: " + error.message;
    return res.status(500).json(dataRes);
  }
};

/**
 * POST /api/notifications/device-token
 * Register/update user's FCM device token.
 */
exports.registerDeviceToken = async (req, res) => {
  const dataRes = { msg: "OK", data: null };
  try {
    const user = await resolveUser(req);
    if (!user) {
      dataRes.msg = "Unauthorized - User not found";
      return res.status(401).json(dataRes);
    }

    const { token, platform } = req.body;
    if (!token || !platform) {
      dataRes.msg = "Missing token or platform in request body";
      return res.status(400).json(dataRes);
    }

    if (!["android", "ios", "web"].includes(platform)) {
      dataRes.msg = "Platform must be one of: android, ios, web";
      return res.status(400).json(dataRes);
    }

    // Try finding existing device record by token
    let device = await userDeviceModel.findOne({ fcm_token: token });

    if (device) {
      device.user_id = user._id;
      device.platform = platform;
      device.is_active = true;
      device.last_active_at = new Date();
      await device.save();
    } else {
      device = await userDeviceModel.create({
        user_id: user._id,
        fcm_token: token,
        platform,
        is_active: true,
        last_active_at: new Date(),
      });
    }

    dataRes.msg = "Device token registered successfully";
    dataRes.data = device;
    return res.status(200).json(dataRes);
  } catch (error) {
    console.error("[NotificationController] Failed to register device token:", error.message);
    dataRes.msg = "Server error: " + error.message;
    return res.status(500).json(dataRes);
  }
};

/**
 * DELETE /api/notifications/device-token
 * Deactivate user's FCM device token (sign out / disable push).
 */
exports.deactivateDeviceToken = async (req, res) => {
  const dataRes = { msg: "OK", data: null };
  try {
    const user = await resolveUser(req);
    if (!user) {
      dataRes.msg = "Unauthorized - User not found";
      return res.status(401).json(dataRes);
    }

    const { token } = req.body;
    if (!token) {
      dataRes.msg = "Missing token in request body";
      return res.status(400).json(dataRes);
    }

    const result = await userDeviceModel.updateOne(
      { fcm_token: token, user_id: user._id },
      { $set: { is_active: false } }
    );

    if (result.matchedCount === 0) {
      dataRes.msg = "Device token not found or does not belong to user";
      return res.status(404).json(dataRes);
    }

    dataRes.msg = "Device token deactivated successfully";
    dataRes.data = null;
    return res.status(200).json(dataRes);
  } catch (error) {
    console.error("[NotificationController] Failed to deactivate device token:", error.message);
    dataRes.msg = "Server error: " + error.message;
    return res.status(500).json(dataRes);
  }
};
