const { orderModel } = require("../models/order.model");
const { orderDetailModel } = require("../models/orderDetail.model");
const { userModel } = require("../models/user.model");
const { escapeRegex } = require("../utils/regex.util");

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

  /**
   * Xây filter cho danh sách đơn hàng của shop, hỗ trợ tìm theo mã đơn hoặc
   * tên/SĐT khách hàng + lọc theo trạng thái — áp dụng ở tầng DB (không phải
   * chỉ lọc trên 10 dòng của trang hiện tại như UI cũ).
   */
  async _buildShopOrderFilter(shopId, { search, status } = {}) {
    const filter = { shop_id: shopId, deleted_at: null };
    if (status && status !== "all") {
      filter.order_status = status;
    }
    const trimmedSearch = search && search.trim();
    if (trimmedSearch) {
      const escaped = escapeRegex(trimmedSearch);
      const matchingUsers = await userModel
        .find({
          $or: [
            { full_name: { $regex: escaped, $options: "i" } },
            { phone: { $regex: escaped, $options: "i" } },
          ],
        })
        .select("_id");
      filter.$or = [
        { order_code: { $regex: escaped, $options: "i" } },
        { user_id: { $in: matchingUsers.map((u) => u._id) } },
      ];
    }
    return filter;
  }

  async findByShopIdPaginated(shopId, { page = 1, limit = 50, search, status } = {}) {
    const filter = await this._buildShopOrderFilter(shopId, { search, status });
    return orderModel.find(filter)
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(limit)
      .populate("user_id");
  }

  async countByShopId(shopId, { search, status } = {}) {
    const filter = await this._buildShopOrderFilter(shopId, { search, status });
    return orderModel.countDocuments(filter);
  }

  async findByIdScoped(id, shopId) {
    return orderModel.findOne({ _id: id, shop_id: shopId, deleted_at: null })
      .populate("user_id")
      .populate("address_id");
  }

  async findDetailsByOrderId(orderId) {
    return orderDetailModel.find({ order_id: orderId, deleted_at: null });
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

  async getDashboardStats(shopId, page = 1) {
    const orders = await orderModel.find({ shop_id: shopId, deleted_at: null }).populate("user_id");

    const totalRevenue = orders
      .filter(o => o.order_status === "completed" && o.payment_status === "paid")
      .reduce((sum, o) => sum + (o.items_total - o.discount_amount), 0);

    const pendingOrders = orders.filter(o => o.order_status === "pending").length;
    const processingOrders = orders.filter(o => ["confirmed", "preparing", "delivering"].includes(o.order_status)).length;
    const completedOrders = orders.filter(o => o.order_status === "completed").length;
    const cancelledOrders = orders.filter(o => o.order_status === "cancelled").length;

    const parsedPage = Math.max(parseInt(page) || 1, 1);
    const limit = 10;
    const sortedOrders = orders.slice().sort((a, b) => b.createdAt - a.createdAt);
    const totalPages = Math.max(Math.ceil(sortedOrders.length / limit), 1);
    const recentOrders = sortedOrders.slice((parsedPage - 1) * limit, parsedPage * limit);

    return {
      totalRevenue,
      totalOrdersCount: orders.length,
      pendingOrders,
      processingOrders,
      completedOrders,
      cancelledOrders,
      recentOrders,
      page: parsedPage,
      totalPages
    };
  }
}

module.exports = new OrderRepository();
