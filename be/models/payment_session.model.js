const db = require("../configs/db");

/**
 * PaymentSession — lưu thông tin giỏ hàng tạm thời TRƯỚC khi chuyển sang SePay.
 * _id của document này được dùng làm order_invoice_number (1 mã duy nhất).
 * Sau khi xác nhận SePay đã thanh toán, service sẽ dùng session này để tạo các Order thực tế.
 */
const paymentSessionSchema = new db.mongoose.Schema(
  {
    user_id: {
      type: db.mongoose.Schema.Types.ObjectId,
      ref: "userModel",
      required: true,
    },
    address_id: {
      type: db.mongoose.Schema.Types.ObjectId,
      ref: "addressModel",
      required: true,
    },
    // Snapshot giỏ hàng đã được validate server-side
    items: [
      {
        product_id: {
          type: db.mongoose.Schema.Types.ObjectId,
          ref: "productModel",
          required: true,
        },
        variant_id: {
          type: db.mongoose.Schema.Types.ObjectId,
          ref: "productVariantModel",
          required: true,
        },
        shop_id: {
          type: db.mongoose.Schema.Types.ObjectId,
          ref: "shopModel",
          required: true,
        },
        quantity: { type: Number, required: true },
        product_name: { type: String, required: true },
        variant_name: { type: String, required: true },
        product_image: { type: String, default: null },
        base_price: { type: Number, required: true },
        selected_options: { type: Array, default: [] },
        option_total_price: { type: Number, required: true, default: 0 },
        unit_price: { type: Number, required: true },
        subtotal: { type: Number, required: true },
        note: { type: String, default: null },
      },
    ],
    // Thông tin thanh toán
    items_total: { type: Number, required: true },
    delivery_fee: { type: Number, required: true, default: 0 },
    discount_amount: { type: Number, required: true, default: 0 },
    total_amount: { type: Number, required: true },
    delivery_option: {
      type: String,
      required: true,
      enum: ["priority", "standard", "saving"],
      default: "standard",
    },
    // Cổng thanh toán đã dùng để tạo session này — quyết định field nào
    // (sepay_* hay vnp_*) được ghi khi confirm, và giá trị payment_method
    // gán cho Order tạo ra từ session.
    gateway: {
      type: String,
      required: true,
      enum: ["sepay", "vnpay"],
      default: "sepay",
    },
    // Voucher snapshot (nếu có)
    voucher_id: {
      type: db.mongoose.Schema.Types.ObjectId,
      ref: "voucherModel",
      default: null,
    },
    order_note: { type: String, default: null },
    // Trạng thái session
    status: {
      type: String,
      required: true,
      // PROCESSING = đang được 1 request confirmPayment xử lý — dùng làm khoá
      // nguyên tử để tránh 2 callback VNPAY (return URL + IPN) xử lý trùng nhau.
      enum: ["PENDING", "PROCESSING", "PAID", "FAILED", "EXPIRED"],
      default: "PENDING",
    },
    // Thông tin giao dịch sau khi xác nhận từ SePay
    sepay_transaction_id: { type: String, default: null },
    sepay_payment_method: { type: String, default: null },
    sepay_status: { type: String, default: null },
    // Thông tin giao dịch sau khi VNPAY callback
    vnp_transaction_no: { type: String, default: null },
    vnp_bank_code: { type: String, default: null },
    vnp_response_code: { type: String, default: null },
    paid_at: { type: Date, default: null },
    // Các order đã được tạo từ session này (sau khi confirm)
    order_ids: [
      {
        type: db.mongoose.Schema.Types.ObjectId,
        ref: "orderModel",
        default: [],
      },
    ],
  },
  {
    collection: "payment_sessions",
    timestamps: true,
  }
);

// TTL index: tự động xóa session PENDING sau 24 giờ
paymentSessionSchema.index(
  { createdAt: 1 },
  { expireAfterSeconds: 86400, partialFilterExpression: { status: "PENDING" } }
);

const paymentSessionModel = db.mongoose.model(
  "paymentSessionModel",
  paymentSessionSchema
);

module.exports = { paymentSessionModel };
