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

const MAX_RANGE_DAYS = 366;

/**
 * Xác định khoảng ngày dùng cho báo cáo: ưu tiên from/to tuỳ chỉnh (dạng
 * YYYY-MM-DD) nếu hợp lệ, ngược lại rơi về cửa sổ trượt N ngày gần nhất (hành
 * vi cũ, giữ tương thích ngược cho các lựa chọn nhanh 7/30/90 ngày).
 */
function resolveDateRange({ days = 30, from, to } = {}) {
  const fromDate = from ? new Date(from) : null;
  const toDate = to ? new Date(to) : null;
  const hasValidCustomRange =
    fromDate && toDate && !isNaN(fromDate.getTime()) && !isNaN(toDate.getTime()) && fromDate <= toDate;

  if (hasValidCustomRange) {
    fromDate.setHours(0, 0, 0, 0);
    toDate.setHours(23, 59, 59, 999);
    const rawNumDays = Math.floor((toDate - fromDate) / 86400000) + 1;
    const numDays = Math.min(Math.max(rawNumDays, 1), MAX_RANGE_DAYS);
    return { sinceDate: fromDate, untilDate: toDate, numDays };
  }

  const sinceDate = new Date();
  sinceDate.setHours(0, 0, 0, 0);
  sinceDate.setDate(sinceDate.getDate() - (days - 1));
  const untilDate = new Date();
  untilDate.setHours(23, 59, 59, 999);
  return { sinceDate, untilDate, numDays: days };
}

class ReportService {
  async getRevenueReport(shopId, { days = 30, from, to } = {}) {
    const { sinceDate, untilDate, numDays } = resolveDateRange({ days, from, to });

    const [rawDaily, topProducts] = await Promise.all([
      reportRepository.getRevenueByDay(shopId, sinceDate, untilDate),
      reportRepository.getTopProducts(shopId, sinceDate, untilDate, 10)
    ]);

    const dailyRevenue = zeroFillDailyRevenue(rawDaily, sinceDate, numDays);

    const totalRevenue = dailyRevenue.reduce((sum, d) => sum + d.revenue, 0);
    const totalOrders = dailyRevenue.reduce((sum, d) => sum + d.orders_count, 0);
    const avgOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0;

    return {
      dailyRevenue,
      topProducts,
      summary: { totalRevenue, totalOrders, avgOrderValue }
    };
  }

  async getPlatformDashboard({ days = 30, from, to } = {}) {
    const { sinceDate, untilDate, numDays } = resolveDateRange({ days, from, to });

    const [rawDaily, topProducts, totalShops, totalProducts, totalCustomers, totalOrders] = await Promise.all([
      reportRepository.getPlatformRevenueByDay(sinceDate, untilDate),
      reportRepository.getPlatformTopProducts(sinceDate, untilDate, 10),
      reportRepository.countTotalShops(),
      reportRepository.countTotalProducts(),
      reportRepository.countTotalCustomers(),
      reportRepository.countTotalOrders()
    ]);

    const dailyRevenue = zeroFillDailyRevenue(rawDaily, sinceDate, numDays);
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
