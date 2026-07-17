const db = require("../configs/db");

const addressSchema = new db.mongoose.Schema(
  {
    user_id: {
      type: db.mongoose.Schema.Types.ObjectId,
      ref: "userModel",
      required: true,
    },
    receiver_name: { type: String, required: true },
    receiver_phone: { type: String, required: true },
    address_detail: { type: String, required: true },
    label: {
      type: String,
      enum: ["home", "company", "other"],
      default: "other",
    },
    location: {
      type: {
        type: String,
        enum: ["Point"],
      },
      coordinates: {
        type: [Number], // [longitude, latitude]
      },
    },
    is_default: { type: Boolean, required: true, default: false },
    deleted_at: { type: Date, default: null },
  },
  { collection: "addresses", timestamps: true },
);

// sparse: bỏ qua các địa chỉ chưa có toạ độ (chưa chọn trên bản đồ)
addressSchema.index({ location: "2dsphere" }, { sparse: true });

let addressModel = db.mongoose.model("addressModel", addressSchema);
module.exports = { addressModel };
