const reportService = require("../../services/report.service");

class AdminDashboardController {
  async showDashboard(req, res) {
    try {
      const days = [7, 30, 90].includes(parseInt(req.query.days)) ? parseInt(req.query.days) : 30;
      const report = await reportService.getPlatformDashboard(days);

      res.render("admin/dashboard", {
        report,
        days,
        admin: req.admin,
        title: "Dashboard Admin",
        activeTab: "dashboard"
      });
    } catch (err) {
      console.error("Show admin dashboard controller error:", err.message);
      res.status(500).render("error", {
        message: "Failed to load dashboard: " + err.message,
        error: err
      });
    }
  }
}

module.exports = new AdminDashboardController();
