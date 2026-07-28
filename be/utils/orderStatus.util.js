const ORDER_STATUS_LABELS = {
  pending: "Chờ xác nhận",
  confirmed: "Đã xác nhận",
  preparing: "Đang chuẩn bị",
  delivering: "Đang giao",
  completed: "Hoàn thành",
  cancelled: "Đã hủy"
};

const PAYMENT_STATUS_LABELS = {
  unpaid: "Chưa thanh toán",
  paid: "Đã thanh toán",
  refunded: "Đã hoàn tiền"
};

module.exports = { ORDER_STATUS_LABELS, PAYMENT_STATUS_LABELS };
