const db = require("../configs/db");

const orderStatusHistorySchema = new db.mongoose.Schema(
  {
    order_id: {
      type: db.mongoose.Schema.Types.ObjectId,
      ref: "orderModel",
      required: true,
    },
    from_status: { type: String, default: null },
    to_status: { type: String, required: true },
    changed_by: {
      type: db.mongoose.Schema.Types.ObjectId,
      ref: "userModel",
      required: true,
    },
    changed_by_name: { type: String, required: true },
    note: { type: String, default: null },
  },
  { collection: "order_status_histories", timestamps: true },
);

let orderStatusHistoryModel = db.mongoose.model(
  "orderStatusHistoryModel",
  orderStatusHistorySchema,
);
module.exports = { orderStatusHistoryModel };
