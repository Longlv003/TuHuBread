const db = require("../configs/db");

const voucherSchema = new db.mongoose.Schema(
  {
    shop_id: {
      type: db.mongoose.Schema.Types.ObjectId,
      ref: "shopModel",
      default: null,
    },
    voucher_code: { type: String, required: true, unique: true },
    voucher_name: { type: String, required: true },
    voucher_type: {
      type: String,
      required: true,
      enum: ["platform", "shop"],
    },
    discount_type: {
      type: String,
      required: true,
      enum: ["percent", "amount", "free_shipping"],
    },
    discount_value: { type: Number, required: true },
    min_order_amount: { type: Number, required: true, default: 0 },
    max_discount_amount: { type: Number, default: null },
    usage_limit: { type: Number, default: null },
    used_count: { type: Number, required: true, default: 0 },
    start_date: { type: Date, required: true },
    end_date: { type: Date, required: true },
    status: {
      type: String,
      required: true,
      enum: ["active", "inactive", "expired"],
      default: "active",
    },
    deleted_at: { type: Date, default: null },
  },
  { collection: "vouchers", timestamps: true },
);

let voucherModel = db.mongoose.model("voucherModel", voucherSchema);
module.exports = { voucherModel };
