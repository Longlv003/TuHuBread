const orderService = require("../../services/order.service");
const { ORDER_STATUS_LABELS, PAYMENT_STATUS_LABELS } = require("../../utils/orderStatus.util");

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

class ShopOrderController {
  /**
   * Render Orders List Page
   */
  async showOrders(req, res) {
    try {
      const search = req.query.search || "";
      const status = req.query.status || "all";
      const { orders, total, page, totalPages } = await orderService.getOrdersForShop(
        req.shop._id,
        req.query.page,
        { search, status },
      );

      res.render("shop/orders", {
        orders,
        total,
        page,
        totalPages,
        search,
        status,
        orderStatusLabels: ORDER_STATUS_LABELS,
        paymentStatusLabels: PAYMENT_STATUS_LABELS,
        firebaseConfig: buildFirebaseConfig(),
        shop: req.shop,
        user: req.user,
        title: "Quản lý Đơn hàng",
        activeTab: "orders"
      });
    } catch (err) {
      console.error("Show orders controller error:", err.message);
      res.status(500).render("error", {
        message: "Failed to load orders: " + err.message,
        error: err
      });
    }
  }

  /**
   * Render Order Detail Page
   */
  async showOrderDetail(req, res) {
    try {
      const { order, items, history, nextStatuses } = await orderService.getOrderDetail(req.shop._id, req.params.id);

      res.render("shop/order_detail", {
        order,
        items,
        history,
        nextStatuses,
        orderStatusLabels: ORDER_STATUS_LABELS,
        paymentStatusLabels: PAYMENT_STATUS_LABELS,
        firebaseConfig: buildFirebaseConfig(),
        shop: req.shop,
        user: req.user,
        title: `Đơn hàng #${order.order_code}`,
        activeTab: "orders"
      });
    } catch (err) {
      console.error("Show order detail controller error:", err.message);
      res.status(404).render("error", {
        message: "Failed to load order: " + err.message,
        error: err
      });
    }
  }

  /**
   * API Post: Update order status
   */
  async updateStatus(req, res) {
    try {
      const { id } = req.params;
      const { order_status, reason } = req.body;

      const result = await orderService.updateOrderStatus(req.shop._id, id, order_status, req.user, reason);
      return res.json({ status: "success", msg: "Cập nhật trạng thái đơn hàng thành công!", data: result });
    } catch (err) {
      console.error("Update order status controller error:", err.message);
      return res.status(400).json({ status: "error", msg: err.message });
    }
  }
}

module.exports = new ShopOrderController();
