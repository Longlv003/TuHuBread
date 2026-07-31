const db = require("../configs/db");

const notificationSchema = new db.mongoose.Schema(
  {
    user_id: {
      type: db.mongoose.Schema.Types.ObjectId,
      ref: "userModel",
      required: true,
    },
    title: { type: String, required: true },
    body: { type: String, required: true },
    type: {
      type: String,
      required: true,
      enum: [
        "order",
        "voucher",
        "system",
        "PAYMENT_SUCCESS",
        "PAYMENT_FAILED",
        "ORDER_CREATED",
        "ORDER_CONFIRMED",
        "ORDER_PREPARING",
        "ORDER_SHIPPING",
        "ORDER_COMPLETED",
        "ORDER_CANCELLED"
      ],
    },
    data: { type: Object, default: null },
    is_read: { type: Boolean, required: true, default: false },
    sent_at: { type: Date, default: null },
    // Ai tạo ra thông báo này — để lịch sử "Thông báo đã gửi" ở Admin/Shop
    // Portal lọc đúng phạm vi (system = tự động sinh, không phải ai chủ động gửi).
    sender_type: {
      type: String,
      enum: ["admin", "shop", "system"],
      default: "system",
    },
    sender_shop_id: {
      type: db.mongoose.Schema.Types.ObjectId,
      ref: "shopModel",
      default: null,
    },
    deleted_at: { type: Date, default: null },
  },
  { collection: "notifications", timestamps: true },
);

let notificationModel = db.mongoose.model(
  "notificationModel",
  notificationSchema,
);
module.exports = { notificationModel };
