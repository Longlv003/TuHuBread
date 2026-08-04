const { reviewModel } = require("../models/review.model");

class ReviewRepository {
  async findById(id) {
    return reviewModel.findById(id);
  }

  async findByShopId(shopId) {
    return reviewModel.find({ shop_id: shopId, deleted_at: null })
      .populate("user_id", "full_name avatar")
      .populate("product_id", "product_name")
      .populate("order_id", "order_code")
      .sort({ createdAt: -1 });
  }

  async findByShopIdPaginated(shopId, { page = 1, limit = 50 }) {
    return reviewModel.find({ shop_id: shopId, deleted_at: null })
      .populate("user_id", "full_name avatar")
      .populate("product_id", "product_name")
      .populate("order_id", "order_code")
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(limit);
  }

  async countByShopId(shopId) {
    return reviewModel.countDocuments({ shop_id: shopId, deleted_at: null });
  }

  async updateStatus(id, status) {
    return reviewModel.findByIdAndUpdate(id, { status }, { new: true });
  }

  /** Toàn bộ đánh giá của 1 đơn hàng (mỗi sản phẩm trong đơn có thể có 1 đánh giá riêng). */
  async findAllByOrderId(orderId) {
    return reviewModel.find({ order_id: orderId, deleted_at: null });
  }

  /** Dùng để kiểm tra unique — 1 sản phẩm trong 1 đơn chỉ được đánh giá 1 lần. */
  async findByOrderAndProduct(orderId, productId) {
    return reviewModel.findOne({ order_id: orderId, product_id: productId, deleted_at: null });
  }

  async findByOrderIds(orderIds) {
    return reviewModel.find({ order_id: { $in: orderIds }, deleted_at: null });
  }

  async create(data) {
    return reviewModel.create(data);
  }
}

module.exports = new ReviewRepository();
