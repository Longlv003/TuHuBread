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
      enum: ["order", "voucher", "system"],
    },
    data: { type: Object, default: null },
    is_read: { type: Boolean, required: true, default: false },
    sent_at: { type: Date, default: null },
    deleted_at: { type: Date, default: null },
  },
  { collection: "notifications", timestamps: true },
);

let notificationModel = db.mongoose.model(
  "notificationModel",
  notificationSchema,
);
module.exports = { notificationModel };
