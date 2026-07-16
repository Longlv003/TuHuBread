const { getIo } = require("../sockets/socket.module");

class SocketService {
  /**
   * Send event to a specific shop's room
   * @param {string} shopId
   * @param {string} event
   * @param {any} data
   */
  emitToShop(shopId, event, data) {
    try {
      const io = getIo();
      io.to(`shop_${shopId}`).emit(event, data);
      console.log(`📡 Emitted event [${event}] to room [shop_${shopId}]`);
    } catch (err) {
      console.error(`Error emitting to shop_${shopId}:`, err.message);
    }
  }

  /**
   * Send event to a specific room
   * @param {string} room
   * @param {string} event
   * @param {any} data
   */
  emitToRoom(room, event, data) {
    try {
      const io = getIo();
      io.to(room).emit(event, data);
      console.log(`📡 Emitted event [${event}] to room [${room}]`);
    } catch (err) {
      console.error(`Error emitting to room ${room}:`, err.message);
    }
  }

  /**
   * Send event to all connected sockets
   * @param {string} event
   * @param {any} data
   */
  emitAll(event, data) {
    try {
      const io = getIo();
      io.emit(event, data);
      console.log(`📡 Emitted event [${event}] to all clients`);
    } catch (err) {
      console.error(`Error emitting to all:`, err.message);
    }
  }

  /**
   * Send a real-time notification
   * @param {any} data
   */
  emitNotification(data) {
    this.emitToRoom("notification", "notification", data);
  }

  /**
   * Send a real-time order update to a shop
   * @param {string} shopId
   * @param {any} orderData
   */
  emitOrderUpdate(shopId, orderData) {
    this.emitToShop(shopId, "order_updated", orderData);
    this.emitToShop(shopId, "dashboard_updated", { trigger: "order" });
  }

  /**
   * Send new order notification to a shop
   * @param {string} shopId
   * @param {any} orderData
   */
  emitNewOrder(shopId, orderData) {
    this.emitToShop(shopId, "new_order", orderData);
    this.emitToShop(shopId, "dashboard_updated", { trigger: "new_order" });
  }
}

module.exports = new SocketService();
