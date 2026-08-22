const orderRepository = require("../repositories/order.repository");
const reportRepository = require("../repositories/report.repository");

const TREND_DAYS = 7;

class DashboardService {
  /**
   * Get shop specific dashboard metrics
   * @param {string} shopId
   */
  async getDashboardData(shopId, page = 1) {
    if (!shopId) {
      throw new Error("Shop ID is required for dashboard queries");
    }

    const since = new Date();
    since.setHours(0, 0, 0, 0);
    since.setDate(since.getDate() - (TREND_DAYS - 1));
    const until = new Date();
    until.setHours(23, 59, 59, 999);

    const [stats, rawDaily] = await Promise.all([
      orderRepository.getDashboardStats(shopId, page),
      reportRepository.getRevenueByDay(shopId, since, until),
    ]);

    // Bù các ngày không có đơn thành 0 để đường biểu đồ liền mạch, không bị
    // nhảy cóc qua ngày vắng khách.
    const byDate = new Map(rawDaily.map((d) => [d._id, d]));
    const revenueTrend = [];
    for (let i = 0; i < TREND_DAYS; i++) {
      const d = new Date(since);
      d.setDate(d.getDate() + i);
      const key = d.toISOString().slice(0, 10);
      const found = byDate.get(key);
      revenueTrend.push({
        date: key,
        revenue: found ? found.revenue : 0,
        orders_count: found ? found.orders_count : 0,
      });
    }

    return { ...stats, revenueTrend };
  }
}

module.exports = new DashboardService();
