const reportRepository = require("../repositories/report.repository");

function formatDate(date) {
  return date.toISOString().slice(0, 10);
}

function zeroFillDailyRevenue(rawDaily, sinceDate, days) {
  const rawByDate = new Map(rawDaily.map(d => [d._id, d]));

  const dailyRevenue = [];
  for (let i = 0; i < days; i++) {
    const d = new Date(sinceDate);
    d.setDate(d.getDate() + i);
    const key = formatDate(d);
    const existing = rawByDate.get(key);
    dailyRevenue.push({
      date: key,
      revenue: existing ? existing.revenue : 0,
      orders_count: existing ? existing.orders_count : 0
    });
  }
  return dailyRevenue;
}

class ReportService {
  async getRevenueReport(shopId, days = 30) {
    const sinceDate = new Date();
    sinceDate.setHours(0, 0, 0, 0);
    sinceDate.setDate(sinceDate.getDate() - (days - 1));

    const [rawDaily, topProducts] = await Promise.all([
      reportRepository.getRevenueByDay(shopId, sinceDate),
      reportRepository.getTopProducts(shopId, sinceDate, 10)
    ]);

    const dailyRevenue = zeroFillDailyRevenue(rawDaily, sinceDate, days);

    const totalRevenue = dailyRevenue.reduce((sum, d) => sum + d.revenue, 0);
    const totalOrders = dailyRevenue.reduce((sum, d) => sum + d.orders_count, 0);
    const avgOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0;

    return {
      dailyRevenue,
      topProducts,
      summary: { totalRevenue, totalOrders, avgOrderValue }
    };
  }

  async getPlatformDashboard(days = 30) {
    const sinceDate = new Date();
    sinceDate.setHours(0, 0, 0, 0);
    sinceDate.setDate(sinceDate.getDate() - (days - 1));

    const [rawDaily, topProducts, totalShops, totalProducts, totalCustomers, totalOrders] = await Promise.all([
      reportRepository.getPlatformRevenueByDay(sinceDate),
      reportRepository.getPlatformTopProducts(sinceDate, 10),
      reportRepository.countTotalShops(),
      reportRepository.countTotalProducts(),
      reportRepository.countTotalCustomers(),
      reportRepository.countTotalOrders()
    ]);

    const dailyRevenue = zeroFillDailyRevenue(rawDaily, sinceDate, days);
    const totalRevenue = dailyRevenue.reduce((sum, d) => sum + d.revenue, 0);
    const totalOrdersInRange = dailyRevenue.reduce((sum, d) => sum + d.orders_count, 0);

    return {
      dailyRevenue,
      topProducts,
      summary: {
        totalRevenue,
        totalOrdersInRange,
        totalShops,
        totalProducts,
        totalCustomers,
        totalOrders
      }
    };
  }
}

module.exports = new ReportService();
