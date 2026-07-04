const db = require("../configs/db");

const cartSchema = new db.mongoose.Schema(
  {
    user_id: {
      type: db.mongoose.Schema.Types.ObjectId,
      ref: "userModel",
      required: true,
    },
    status: {
      type: String,
      required: true,
      enum: ["active", "ordered", "abandoned"],
      default: "active",
    },
    cart_total: { type: Number, required: true, default: 0 },
    deleted_at: { type: Date, default: null },
  },
  { collection: "carts", timestamps: true },
);

// Enforce unique active cart per user
cartSchema.index(
  { user_id: 1 },
  { unique: true, partialFilterExpression: { status: "active" } },
);

let cartModel = db.mongoose.model("cartModel", cartSchema);
module.exports = { cartModel };
