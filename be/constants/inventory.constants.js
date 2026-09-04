/**
 * Shop Portal không còn cho chủ shop nhập số tồn kho cụ thể — sản phẩm/biến
 * thể chỉ còn bật/tắt bán qua trường `status` ("active"/"inactive"). Tồn kho
 * (stock_quantity) vẫn tồn tại trong DB vì luồng đặt hàng/thanh toán dùng nó
 * để trừ kho nguyên tử (order.service.js#_claimStock), tránh oversell khi 2
 * khách đặt cùng lúc — chỉ là không còn ai NHẬP số này qua form nữa.
 *
 * Khi form không gửi `stockQuantity` (trường đã bị bỏ khỏi giao diện), khởi
 * tạo với 1 số rất lớn để việc trừ kho không bao giờ thực sự chặn đơn hàng —
 * tương đương "không giới hạn" từ góc nhìn chủ shop.
 */
const UNLIMITED_STOCK_FALLBACK = 999999;

module.exports = { UNLIMITED_STOCK_FALLBACK };
