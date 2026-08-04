const reportService = require("../../services/report.service");

class AdminDashboardController {
  async showDashboard(req, res) {
    try {
      const days = [7, 30, 90].includes(parseInt(req.query.days)) ? parseInt(req.query.days) : 30;
      const from = req.query.from || "";
      const to = req.query.to || "";
      const report = await reportService.getPlatformDashboard({ days, from, to });

      res.render("admin/dashboard", {
        report,
        days,
        from,
        to,
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
