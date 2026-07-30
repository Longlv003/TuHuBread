const { notificationModel } = require("../models/notification.model");

class NotificationRepository {
  async create(data) {
    return notificationModel.create(data);
  }

  async insertMany(docs) {
    return notificationModel.insertMany(docs);
  }

  async findAllPaginated(page = 1, limit = 20) {
    return notificationModel.find({ deleted_at: null })
      .populate("user_id", "full_name email")
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(limit);
  }

  async countAll() {
    return notificationModel.countDocuments({ deleted_at: null });
  }

  async findByUserIdPaginated(userId, { page = 1, limit = 20 }) {
    return notificationModel.find({ user_id: userId, deleted_at: null })
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(limit);
  }

  async countByUserId(userId) {
    return notificationModel.countDocuments({ user_id: userId, deleted_at: null });
  }

  async countUnreadByUserId(userId) {
    return notificationModel.countDocuments({ user_id: userId, is_read: false, deleted_at: null });
  }

  async findByIdScoped(id, userId) {
    return notificationModel.findOne({ _id: id, user_id: userId, deleted_at: null });
  }

  async markRead(id) {
    return notificationModel.findByIdAndUpdate(id, { is_read: true }, { new: true });
  }

  async markAllReadForUser(userId) {
    return notificationModel.updateMany({ user_id: userId, is_read: false, deleted_at: null }, { is_read: true });
  }

  async countUnreadByUserIdGroupedByType(userId) {
    const rows = await notificationModel.aggregate([
      { $match: { user_id: userId, is_read: false, deleted_at: null } },
      { $group: { _id: "$type", count: { $sum: 1 } } },
    ]);
    const result = { order: 0, voucher: 0, system: 0 };
    for (const row of rows) {
      result[row._id] = row.count;
    }
    return result;
  }

  async softDeleteScoped(id, userId) {
    return notificationModel.findOneAndUpdate(
      { _id: id, user_id: userId },
      { deleted_at: new Date() },
      { new: true },
    );
  }

  async softDeleteAllForUser(userId) {
    return notificationModel.updateMany({ user_id: userId, deleted_at: null }, { deleted_at: new Date() });
  }

  async findByShopSenderPaginated(shopId, { page = 1, limit = 10 }) {
    return notificationModel.find({ sender_shop_id: shopId, deleted_at: null })
      .populate("user_id", "full_name email")
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(limit);
  }

  async countByShopSender(shopId) {
    return notificationModel.countDocuments({ sender_shop_id: shopId, deleted_at: null });
  }
}

module.exports = new NotificationRepository();
