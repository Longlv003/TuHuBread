const db = require("../configs/db");

const orderSchema = new db.mongoose.Schema(
  {
    order_code: { type: String, required: true, unique: true },
    user_id: {
      type: db.mongoose.Schema.Types.ObjectId,
      ref: "userModel",
      required: true,
    },
    shop_id: {
      type: db.mongoose.Schema.Types.ObjectId,
      ref: "shopModel",
      required: true,
    },
    voucher_id: {
      type: db.mongoose.Schema.Types.ObjectId,
      ref: "voucherModel",
      default: null,
    },
    address_id: {
      type: db.mongoose.Schema.Types.ObjectId,
      ref: "addressModel",
      required: true,
    },
    payment_method: {
      type: String,
      required: true,
      enum: ["cash", "momo", "zalopay", "bank", "vnpay"],
    },
    delivery_option: {
      type: String,
      required: true,
      enum: ["priority", "standard", "saving"],
      default: "standard",
    },
    payment_status: {
      type: String,
      required: true,
      enum: ["unpaid", "paid", "refunded"],
      default: "unpaid",
    },
    order_status: {
      type: String,
      required: true,
      enum: [
        "pending",
        "confirmed",
        "preparing",
        "delivering",
        "completed",
        "cancelled",
      ],
      default: "pending",
    },
    items_total: { type: Number, required: true },
    discount_amount: { type: Number, required: true, default: 0 },
    delivery_fee: { type: Number, required: true, default: 0 },
    total_amount: { type: Number, required: true },
    note: { type: String, default: null },
    deleted_at: { type: Date, default: null },
  },
  { collection: "orders", timestamps: true },
);

let orderModel = db.mongoose.model("orderModel", orderSchema);
module.exports = { orderModel };
