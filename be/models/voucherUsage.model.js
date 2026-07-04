const db = require("../configs/db");

const voucherUsageSchema = new db.mongoose.Schema(
  {
    voucher_id: {
      type: db.mongoose.Schema.Types.ObjectId,
      ref: "voucherModel",
      required: true,
    },
    user_id: {
      type: db.mongoose.Schema.Types.ObjectId,
      ref: "userModel",
      required: true,
    },
    order_id: {
      type: db.mongoose.Schema.Types.ObjectId,
      ref: "orderModel",
      required: true,
    },
    voucher_code: { type: String, required: true },
    discount_amount: { type: Number, required: true },
    used_at: { type: Date, required: true, default: Date.now },
    deleted_at: { type: Date, default: null },
  },
  { collection: "voucher_usages", timestamps: true },
);

let voucherUsageModel = db.mongoose.model(
  "voucherUsageModel",
  voucherUsageSchema,
);
module.exports = { voucherUsageModel };
