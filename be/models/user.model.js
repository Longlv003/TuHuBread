const db = require("../configs/db");

const userSchema = new db.mongoose.Schema(
  {
    firebase_uid: { type: String, required: true, unique: true },
    full_name: { type: String, required: true },
    email: { type: String, default: null },
    avatar: { type: String, default: null },
    role: {
      type: String,
      required: true,
      enum: ["customer", "shop_owner", "admin", "driver"],
      default: "customer",
    },
    status: {
      type: String,
      required: true,
      enum: ["active", "inactive", "blocked"],
      default: "active",
    },
    deleted_at: { type: Date, default: null },
  },
  { collection: "users", timestamps: true },
);

let userModel = db.mongoose.model("userModel", userSchema);
module.exports = { userModel };
