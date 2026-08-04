const reportService = require("../../services/report.service");

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

class ShopReportController {
  async showReport(req, res) {
    try {
      const days = [7, 30, 90].includes(parseInt(req.query.days)) ? parseInt(req.query.days) : 30;
      const from = req.query.from || "";
      const to = req.query.to || "";
      const report = await reportService.getRevenueReport(req.shop._id, { days, from, to });

      res.render("shop/reports", {
        report,
        days,
        from,
        to,
        firebaseConfig: buildFirebaseConfig(),
        shop: req.shop,
        user: req.user,
        title: "Báo cáo Doanh thu",
        activeTab: "reports"
      });
    } catch (err) {
      console.error("Show report controller error:", err.message);
      res.status(500).render("error", {
        message: "Failed to load report: " + err.message,
        error: err
      });
    }
  }
}

module.exports = new ShopReportController();
