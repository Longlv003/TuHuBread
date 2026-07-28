const { orderStatusHistoryModel } = require("../models/orderStatusHistory.model");

class OrderStatusHistoryRepository {
  async create(data) {
    return orderStatusHistoryModel.create(data);
  }

  async findByOrderId(orderId) {
    return orderStatusHistoryModel.find({ order_id: orderId }).sort({ createdAt: 1 });
  }
}

module.exports = new OrderStatusHistoryRepository();
