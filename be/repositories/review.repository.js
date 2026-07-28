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

  async updateStatus(id, status) {
    return reviewModel.findByIdAndUpdate(id, { status }, { new: true });
  }
}

module.exports = new ReviewRepository();
