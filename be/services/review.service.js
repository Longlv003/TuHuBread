const mongoose = require("mongoose");
const reviewRepository = require("../repositories/review.repository");
const { reviewModel } = require("../models/review.model");
const { orderModel } = require("../models/order.model");
const { orderDetailModel } = require("../models/orderDetail.model");
const { shopModel } = require("../models/shop.model");

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

    const review = await reviewRepository.create({
      user_id: userId,
      shop_id: order.shop_id,
      product_id: productId,
      order_id: orderId,
      rating: parsedRating,
      comment: comment && comment.trim() ? comment.trim() : null,
      images: Array.isArray(images) ? images : [],
    });

    await this.recalculateShopRating(order.shop_id);

    return review;
  }

  /**
   * Tính lại rating_average / total_reviews của cửa hàng từ các đánh giá đang
   * hiển thị.
   *
   * Hai trường này được lưu sẵn trong shopModel (thay vì tính động như rating
   * sản phẩm) nhưng trước đây không có chỗ nào cập nhật, nên luôn đứng yên ở 0
   * và app hiển thị "Chưa có đánh giá" kể cả khi khách đã đánh giá.
   *
   * Chỉ đếm review "visible": khi chủ shop ẩn 1 đánh giá thì nó cũng phải biến
   * mất khỏi điểm trung bình, nếu không việc ẩn chỉ có tác dụng nửa vời.
   * @param {string|import('mongoose').Types.ObjectId} shopId
   */
  async recalculateShopRating(shopId) {
    const [stats] = await reviewModel.aggregate([
      {
        $match: {
          shop_id: new mongoose.Types.ObjectId(String(shopId)),
          status: "visible",
          deleted_at: null,
        },
      },
      { $group: { _id: null, average: { $avg: "$rating" }, total: { $sum: 1 } } },
    ]);

    await shopModel.findByIdAndUpdate(shopId, {
      // Làm tròn 1 chữ số thập phân cho khớp cách hiển thị ở app (vd. 4.7).
      rating_average: stats ? Math.round(stats.average * 10) / 10 : 0,
      total_reviews: stats ? stats.total : 0,
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
    const updated = await reviewRepository.updateStatus(reviewId, newStatus);

    await this.recalculateShopRating(review.shop_id);

    return updated;
  }
}

module.exports = new ReviewService();
