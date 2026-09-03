const orderRepository = require("../repositories/order.repository");
const productVariantRepository = require("../repositories/productVariant.repository");
const reportRepository = require("../repositories/report.repository");

/** Tồn kho từ mức này trở xuống thì coi là sắp hết và đưa vào cảnh báo. */
const LOW_STOCK_THRESHOLD = 5;

/** Số dòng tối đa cho mỗi khối "Top sản phẩm" / "Sắp hết hàng". */
const TOP_PRODUCTS_LIMIT = 5;
const LOW_STOCK_LIMIT = 5;

/** Các trạng thái shop còn phải xử lý (chưa xong, chưa huỷ). */
const ACTIVE_STATUSES = ["pending", "confirmed", "preparing", "delivering"];

/** Mốc 00:00:00 và 23:59:59 của ngày hôm nay theo giờ máy chủ. */
function todayRange() {
  const start = new Date();
  start.setHours(0, 0, 0, 0);
  const end = new Date();
  end.setHours(23, 59, 59, 999);
  return { start, end };
}

class DashboardService {
  /**
   * Số liệu cho Dashboard shop — trả lời câu hỏi "hôm nay cửa hàng thế nào".
   *
   * Các chỉ số tổng kết (doanh thu, tổng đơn, đơn xong, đơn huỷ) đều tính
   * TRONG NGÀY HÔM NAY. Riêng "chờ xác nhận" và "đang xử lý" là hàng đợi việc
   * cần làm nên đếm toàn bộ, không giới hạn ngày — một đơn từ hôm qua chưa
   * xác nhận thì hôm nay vẫn phải xử lý, ẩn đi là bỏ sót.
   *
   * Xu hướng doanh thu nhiều ngày đã chuyển hẳn sang trang Báo cáo doanh thu.
   * @param {string} shopId
   * @param {number|string} page trang của bảng "Đơn hàng mới nhất"
   */
  async getDashboardData(shopId, page = 1) {
    if (!shopId) {
      throw new Error("Shop ID is required for dashboard queries");
    }

    const { start, end } = todayRange();

    const [
      todayRevenue,
      todayStatusCounts,
      recent,
      topProductsToday,
      lowStockVariants,
      unpaidOrders,
      activeOrders,
    ] = await Promise.all([
      orderRepository.getRevenueBetween(shopId, start, end),
      orderRepository.countByStatusBetween(shopId, start, end),
      orderRepository.getRecentOrders(shopId, page),
      reportRepository.getTopProducts(shopId, start, end, TOP_PRODUCTS_LIMIT),
      productVariantRepository.findLowStockByShopId(shopId, {
        threshold: LOW_STOCK_THRESHOLD,
        limit: LOW_STOCK_LIMIT,
      }),
      orderRepository.countUnpaidActive(shopId),
      orderRepository.countByStatuses(shopId, ACTIVE_STATUSES),
    ]);

    const todayTotalOrders = Object.values(todayStatusCounts).reduce((sum, n) => sum + n, 0);
    const pendingOrders = await orderRepository.countByStatuses(shopId, ["pending"]);

    return {
      // KPI
      totalRevenue: todayRevenue.revenue,
      totalOrdersCount: todayTotalOrders,
      pendingOrders,
      processingOrders: activeOrders - pendingOrders,
      completedOrders: todayStatusCounts.completed || 0,
      cancelledOrders: todayStatusCounts.cancelled || 0,

      // Bảng đơn hàng mới nhất
      recentOrders: recent.orders,
      page: recent.page,
      totalPages: recent.totalPages,

      topProductsToday,

      alerts: {
        lowStockVariants,
        lowStockThreshold: LOW_STOCK_THRESHOLD,
        unpaidOrders,
        pendingOrders,
      },
    };
  }
}

module.exports = new DashboardService();
