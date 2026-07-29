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
}

module.exports = new NotificationRepository();
