/**
 * Notification Routes
 */

const express = require("express");
const router = express.Router();
const notificationCtrl = require("../controllers/notification.controller");
const { firebaseAuth } = require("../middlewares/auth.middlewares");

// Apply authentication middleware to all notification routes
router.use(firebaseAuth);

router.get("/", notificationCtrl.getNotifications);
router.get("/unread-count", notificationCtrl.getUnreadCount);
router.patch("/read-all", notificationCtrl.markAllAsRead);
router.patch("/:notificationId/read", notificationCtrl.markAsRead);
router.post("/device-token", notificationCtrl.registerDeviceToken);
router.delete("/device-token", notificationCtrl.deactivateDeviceToken);

module.exports = router;
