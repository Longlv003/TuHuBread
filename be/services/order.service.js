const orderRepository = require("../repositories/order.repository");
const orderStatusHistoryRepository = require("../repositories/orderStatusHistory.repository");
const socketService = require("./socket.service");

const ORDER_FLOW = ["pending", "confirmed", "preparing", "delivering", "completed"];

/**
 * Get the list of order_status values a shop owner may transition an order into.
 * @param {string} currentStatus
 */
function getAllowedNextStatuses(currentStatus) {
  if (currentStatus === "cancelled" || currentStatus === "completed") {
    return [];
  }

  const idx = ORDER_FLOW.indexOf(currentStatus);
  const next = idx >= 0 && idx < ORDER_FLOW.length - 1 ? [ORDER_FLOW[idx + 1]] : [];

  if (currentStatus === "pending" || currentStatus === "confirmed") {
    next.push("cancelled");
  }

  return next;
}

class OrderService {
  getAllowedNextStatuses(currentStatus) {
    return getAllowedNextStatuses(currentStatus);
  }

  async getOrdersForShop(shopId) {
    return orderRepository.findByShopId(shopId, 300);
  }

  async getOrderDetail(shopId, orderId) {
    const order = await orderRepository.findByIdScoped(orderId, shopId);
    if (!order) {
      throw new Error("Order not found");
    }
    const [items, history] = await Promise.all([
      orderRepository.findDetailsByOrderId(orderId),
      orderStatusHistoryRepository.findByOrderId(orderId)
    ]);
    return { order, items, history, nextStatuses: getAllowedNextStatuses(order.order_status) };
  }

  async updateOrderStatus(shopId, orderId, newStatus, changedByAccount) {
    const order = await orderRepository.findByIdScoped(orderId, shopId);
    if (!order) {
      throw new Error("Order not found");
    }

    const allowed = getAllowedNextStatuses(order.order_status);
    if (!allowed.includes(newStatus)) {
      throw new Error(`Không thể chuyển từ '${order.order_status}' sang '${newStatus}'`);
    }

    let paymentStatus;
    if (newStatus === "completed" && order.payment_method === "cash" && order.payment_status === "unpaid") {
      paymentStatus = "paid";
    }

    const previousStatus = order.order_status;
    const updated = await orderRepository.updateStatus(orderId, newStatus, paymentStatus);

    if (changedByAccount) {
      await orderStatusHistoryRepository.create({
        order_id: orderId,
        from_status: previousStatus,
        to_status: newStatus,
        changed_by: changedByAccount._id,
        changed_by_name: changedByAccount.full_name
      });
    }

    socketService.emitOrderUpdate(String(shopId), updated);
    return updated;
  }
}

module.exports = new OrderService();
