const reviewRepository = require("../repositories/review.repository");

class ReviewService {
  async getReviewsByShop(shopId) {
    return reviewRepository.findByShopId(shopId);
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
