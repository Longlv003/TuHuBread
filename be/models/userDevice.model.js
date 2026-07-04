const db = require("../configs/db");

const userDeviceSchema = new db.mongoose.Schema(
  {
    user_id: {
      type: db.mongoose.Schema.Types.ObjectId,
      ref: "userModel",
      required: true,
    },
    fcm_token: { type: String, required: true, unique: true },
    device_id: { type: String, default: null },
    platform: {
      type: String,
      required: true,
      enum: ["android", "ios", "web"],
    },
    device_name: { type: String, default: null },
    is_active: { type: Boolean, required: true, default: true },
    last_active_at: { type: Date, default: null },
    deleted_at: { type: Date, default: null },
  },
  { collection: "user_devices", timestamps: true },
);

let userDeviceModel = db.mongoose.model("userDeviceModel", userDeviceSchema);
module.exports = { userDeviceModel };
