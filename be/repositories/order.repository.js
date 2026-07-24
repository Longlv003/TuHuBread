const { orderModel } = require("../models/order.model");
const { orderDetailModel } = require("../models/orderDetail.model");

class OrderRepository {
  async findById(id) {
    return orderModel.findById(id).populate("user_id").populate("address_id");
  }

  async findByOrderCode(orderCode) {
    return orderModel.findOne({ order_code: orderCode, deleted_at: null });
  }

  async findByShopId(shopId, limit = 50) {
    return orderModel.find({ shop_id: shopId, deleted_at: null })
      .sort({ createdAt: -1 })
      .limit(limit)
      .populate("user_id");
  }

  async createOrder(orderData) {
    return await orderModel.create(orderData);
  }

  async createOrderDetail(orderDetailData) {
    return await orderDetailModel.create(orderDetailData);
  }

  async updateStatus(id, orderStatus, paymentStatus) {
    const updateData = {};
    if (orderStatus) updateData.order_status = orderStatus;
    if (paymentStatus) updateData.payment_status = paymentStatus;
    return orderModel.findByIdAndUpdate(id, updateData, { new: true });
  }

  async getDashboardStats(shopId) {
    const orders = await orderModel.find({ shop_id: shopId, deleted_at: null });

    const totalRevenue = orders
      .filter(o => o.order_status === "completed" && o.payment_status === "paid")
      .reduce((sum, o) => sum + o.total_amount, 0);

    const pendingOrders = orders.filter(o => o.order_status === "pending").length;
    const processingOrders = orders.filter(o => ["confirmed", "preparing", "delivering"].includes(o.order_status)).length;
    const completedOrders = orders.filter(o => o.order_status === "completed").length;
    const cancelledOrders = orders.filter(o => o.order_status === "cancelled").length;

    return {
      totalRevenue,
      totalOrdersCount: orders.length,
      pendingOrders,
      processingOrders,
      completedOrders,
      cancelledOrders,
      recentOrders: orders.sort((a, b) => b.createdAt - a.createdAt).slice(0, 10)
    };
  }
}

module.exports = new OrderRepository();
