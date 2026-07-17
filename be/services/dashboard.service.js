const orderRepository = require("../repositories/order.repository");

class DashboardService {
  /**
   * Get shop specific dashboard metrics
   * @param {string} shopId
   */
  async getDashboardData(shopId) {
    if (!shopId) {
      throw new Error("Shop ID is required for dashboard queries");
    }
    return orderRepository.getDashboardStats(shopId);
  }
}

module.exports = new DashboardService();
