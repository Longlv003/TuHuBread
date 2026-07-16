const dashboardService = require("../../services/dashboard.service");

class ShopDashboardController {
  /**
   * Render Dashboard Page
   */
  async showDashboard(req, res) {
    try {
      const shopId = req.shop._id;
      const stats = await dashboardService.getDashboardData(shopId);

      const firebaseConfig = {
        apiKey: process.env.FIREBASE_API_KEY,
        authDomain: process.env.FIREBASE_AUTH_DOMAIN,
        projectId: process.env.FIREBASE_PROJECT_ID,
        storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
        messagingSenderId: process.env.FIREBASE_MESSAGING_SENDER_ID,
        appId: process.env.FIREBASE_APP_ID
      };

      res.render("shop/dashboard", {
        stats,
        firebaseConfig,
        shop: req.shop,
        user: req.user,
        title: "Bảng Điều Khiển",
        activeTab: "dashboard"
      });
    } catch (err) {
      console.error("Dashboard controller error:", err.message);
      res.status(500).render("error", {
        message: "Failed to load dashboard data: " + err.message,
        error: err
      });
    }
  }
}

module.exports = new ShopDashboardController();
