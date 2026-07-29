const reviewService = require("../../services/review.service");
const productRepository = require("../../repositories/product.repository");

function buildFirebaseConfig() {
  return {
    apiKey: process.env.FIREBASE_API_KEY,
    authDomain: process.env.FIREBASE_AUTH_DOMAIN,
    projectId: process.env.FIREBASE_PROJECT_ID,
    storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
    messagingSenderId: process.env.FIREBASE_MESSAGING_SENDER_ID,
    appId: process.env.FIREBASE_APP_ID
  };
}

class ShopReviewController {
  async showReviews(req, res) {
    try {
      const [{ reviews, total, page, totalPages }, products] = await Promise.all([
        reviewService.getReviewsByShopPaginated(req.shop._id, req.query.page),
        productRepository.findByShopId(req.shop._id)
      ]);

      res.render("shop/reviews", {
        reviews,
        total,
        page,
        totalPages,
        products,
        firebaseConfig: buildFirebaseConfig(),
        shop: req.shop,
        user: req.user,
        title: "Đánh giá khách hàng",
        activeTab: "reviews"
      });
    } catch (err) {
      console.error("Show reviews controller error:", err.message);
      res.status(500).render("error", {
        message: "Failed to load reviews: " + err.message,
        error: err
      });
    }
  }

  async toggleStatus(req, res) {
    try {
      const { id } = req.params;
      const result = await reviewService.toggleVisibility(req.shop._id, id);
      return res.json({ status: "success", msg: "Cập nhật trạng thái đánh giá thành công!", data: result });
    } catch (err) {
      console.error("Toggle review status controller error:", err.message);
      return res.status(400).json({ status: "error", msg: err.message });
    }
  }
}

module.exports = new ShopReviewController();
