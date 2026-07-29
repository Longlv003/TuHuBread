const reviewRepository = require("../repositories/review.repository");

class ReviewService {
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
