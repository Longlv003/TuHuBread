const reviewRepository = require("../repositories/review.repository");
const { orderModel } = require("../models/order.model");
const { orderDetailModel } = require("../models/orderDetail.model");

class ReviewService {
  /**
   * Khách hàng đánh giá 1 đơn hàng đã hoàn thành — mỗi đơn chỉ đánh giá được
   * 1 lần. Gắn product_id vào sản phẩm đầu tiên của đơn để đánh giá cũng
   * hiện lên trang chi tiết sản phẩm đó, dù về bản chất là đánh giá cho cả
   * trải nghiệm đơn hàng/cửa hàng.
   */
  async createReviewForOrder(userId, orderId, { rating, comment }) {
    const parsedRating = parseInt(rating);
    if (!parsedRating || parsedRating < 1 || parsedRating > 5) {
      throw new Error("Số sao đánh giá phải từ 1 đến 5");
    }

    const order = await orderModel.findOne({ _id: orderId, user_id: userId, deleted_at: null });
    if (!order) {
      throw new Error("Không tìm thấy đơn hàng");
    }
    if (order.order_status !== "completed") {
      throw new Error("Chỉ có thể đánh giá đơn hàng đã hoàn thành");
    }

    const existing = await reviewRepository.findByOrderId(orderId);
    if (existing) {
      throw new Error("Đơn hàng này đã được đánh giá rồi");
    }

    const firstItem = await orderDetailModel.findOne({ order_id: orderId, deleted_at: null });

    return reviewRepository.create({
      user_id: userId,
      shop_id: order.shop_id,
      product_id: firstItem ? firstItem.product_id : null,
      order_id: orderId,
      rating: parsedRating,
      comment: comment && comment.trim() ? comment.trim() : null,
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
