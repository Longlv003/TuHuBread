const mongoose = require("mongoose");
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
    return orderModel.findByIdAndUpdate(id, updateData, { new: true, runValidators: true });
  }

  /**
   * Doanh thu của các đơn hoàn thành & đã thanh toán trong khoảng thời gian.
   * Tính bằng aggregate thay vì tải hết đơn về rồi cộng trong JS.
   */
  async getRevenueBetween(shopId, since, until) {
    const [row] = await orderModel.aggregate([
      {
        $match: {
          shop_id: new mongoose.Types.ObjectId(String(shopId)),
          order_status: "completed",
          payment_status: "paid",
          deleted_at: null,
          createdAt: { $gte: since, $lte: until },
        },
      },
      {
        $group: {
          _id: null,
          revenue: { $sum: { $subtract: ["$items_total", "$discount_amount"] } },
          orders_count: { $sum: 1 },
        },
      },
    ]);
    return { revenue: row ? row.revenue : 0, ordersCount: row ? row.orders_count : 0 };
  }

  /** Đếm đơn theo trạng thái trong khoảng thời gian (một lượt cho mọi trạng thái). */
  async countByStatusBetween(shopId, since, until) {
    const rows = await orderModel.aggregate([
      {
        $match: {
          shop_id: new mongoose.Types.ObjectId(String(shopId)),
          deleted_at: null,
          createdAt: { $gte: since, $lte: until },
        },
      },
      { $group: { _id: "$order_status", count: { $sum: 1 } } },
    ]);
    return rows.reduce((acc, r) => ({ ...acc, [r._id]: r.count }), {});
  }

  /**
   * Đơn khách đã nhận nhưng chưa trả tiền — dùng cho ô cảnh báo ở Dashboard.
   * Đơn đã huỷ không tính vì không còn phải thu tiền nữa.
   */
  async countUnpaidActive(shopId) {
    return orderModel.countDocuments({
      shop_id: shopId,
      payment_status: "unpaid",
      order_status: { $ne: "cancelled" },
      deleted_at: null,
    });
  }

  /** Đơn đang ở 1 trong các trạng thái cần shop xử lý (không giới hạn ngày). */
  async countByStatuses(shopId, statuses) {
    return orderModel.countDocuments({
      shop_id: shopId,
      order_status: { $in: statuses },
      deleted_at: null,
    });
  }

  /**
   * Trang danh sách "Đơn hàng mới nhất" trên Dashboard.
   *
   * Trước đây hàm này tải TOÀN BỘ đơn của shop về rồi mới lọc/đếm/cắt trang
   * bằng JavaScript — càng bán được nhiều đơn thì mở Dashboard càng chậm và
   * càng tốn RAM. Giờ đếm và phân trang ngay trong MongoDB.
   */
  async getRecentOrders(shopId, page = 1) {
    const parsedPage = Math.max(parseInt(page) || 1, 1);
    const limit = 10;
    const filter = { shop_id: shopId, deleted_at: null };

    const [orders, total] = await Promise.all([
      orderModel
        .find(filter)
        .populate("user_id")
        .sort({ createdAt: -1 })
        .skip((parsedPage - 1) * limit)
        .limit(limit),
      orderModel.countDocuments(filter),
    ]);

    return {
      orders,
      page: parsedPage,
      totalPages: Math.max(Math.ceil(total / limit), 1),
    };
  }
}

module.exports = new OrderRepository();
