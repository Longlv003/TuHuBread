const reviewRepository = require("../repositories/review.repository");
const { orderModel } = require("../models/order.model");
const { orderDetailModel } = require("../models/orderDetail.model");

class ReviewService {
  /**
   * Khách hàng đánh giá 1 SẢN PHẨM cụ thể trong 1 đơn hàng đã hoàn thành —
   * mỗi sản phẩm trong đơn chỉ đánh giá được 1 lần (đơn có nhiều sản phẩm thì
   * đánh giá riêng từng sản phẩm, không gộp chung 1 đánh giá cho cả đơn).
   */
  async createReviewForOrder(userId, orderId, { productId, rating, comment, images }) {
    const parsedRating = parseInt(rating);
    if (!parsedRating || parsedRating < 1 || parsedRating > 5) {
      throw new Error("Số sao đánh giá phải từ 1 đến 5");
    }
    if (!productId) {
      throw new Error("Thiếu sản phẩm cần đánh giá");
    }

    const order = await orderModel.findOne({ _id: orderId, user_id: userId, deleted_at: null });
    if (!order) {
      throw new Error("Không tìm thấy đơn hàng");
    }
    if (order.order_status !== "completed") {
      throw new Error("Chỉ có thể đánh giá đơn hàng đã hoàn thành");
    }

    // Xác nhận sản phẩm này thực sự nằm trong đơn hàng — không tin product_id
    // client gửi lên một cách vô điều kiện.
    const orderItem = await orderDetailModel.findOne({ order_id: orderId, product_id: productId, deleted_at: null });
    if (!orderItem) {
      throw new Error("Sản phẩm này không thuộc đơn hàng");
    }

    const existing = await reviewRepository.findByOrderAndProduct(orderId, productId);
    if (existing) {
      throw new Error("Sản phẩm này trong đơn hàng đã được đánh giá rồi");
    }

    return reviewRepository.create({
      user_id: userId,
      shop_id: order.shop_id,
      product_id: productId,
      order_id: orderId,
      rating: parsedRating,
      comment: comment && comment.trim() ? comment.trim() : null,
      images: Array.isArray(images) ? images : [],
    });
  }

  async getReviewsByShop(shopId) {
    return reviewRepository.findByShopId(shopId);
  }

  async getReviewsByShopPaginated(shopId, page = 1) {
    const parsedPage = Math.max(parseInt(page) || 1, 1);
    const limit = 10;
    const [reviews, total] = await Promise.all([
      reviewRepository.findByShopIdPaginated(shopId, { page: parsedPage, limit }),
      reviewRepository.countByShopId(shopId),
    ]);
    return {
      reviews,
      total,
      page: parsedPage,
      totalPages: Math.max(Math.ceil(total / limit), 1),
    };
  }

  async toggleVisibility(shopId, reviewId) {
    const review = await reviewRepository.findById(reviewId);
    if (!review || String(review.shop_id) !== String(shopId)) {
      throw new Error("Review not found");
    }

    const newStatus = review.status === "visible" ? "hidden" : "visible";
    return reviewRepository.updateStatus(reviewId, newStatus);
  }
}

module.exports = new ReviewService();
