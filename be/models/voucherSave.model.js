const db = require("../configs/db");

// Ghi nhận user đã save (claim) voucher.
// Unique index (voucher_id + user_id): 1 user chỉ save 1 voucher 1 lần.
const voucherSaveSchema = new db.mongoose.Schema(
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
    voucher_code: { type: String, required: true }, // snapshot mã lúc save
    expires_at: { type: Date, required: true },     // snapshot end_date lúc save
    status: {
      type: String,
      required: true,
      enum: ["saved", "used", "expired"],
      default: "saved",
    },
    saved_at: { type: Date, required: true, default: Date.now },
    used_at: { type: Date, default: null },
    deleted_at: { type: Date, default: null },
  },
  { collection: "voucher_saves", timestamps: true },
);

// Đảm bảo mỗi user chỉ save mỗi voucher 1 lần
voucherSaveSchema.index({ voucher_id: 1, user_id: 1 }, { unique: true });

let voucherSaveModel = db.mongoose.model("voucherSaveModel", voucherSaveSchema);
module.exports = { voucherSaveModel };
