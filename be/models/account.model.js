const db = require("../configs/db");

const accSchema = new db.mongoose.Schema(
  {
    firebase_uid: { type: String, required: true, unique: true },
    full_name: { type: String },
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
    },
    phone_number: { type: String, unique: true },
    role: {
      type: String,
      enum: ["superAdmin", "admin", "user"],
      default: "user",
    },
    avatar: { type: String, default: null },
    is_active: { type: Boolean, default: true },
    deleted_at: { type: Date, default: null },
  },
  { collection: "accounts", timestamps: true },
);

let accModel = db.mongoose.model("accModel", accSchema);
module.exports = { accModel };
