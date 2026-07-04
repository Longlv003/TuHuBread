const db = require("../configs/db");

const reviewSchema = new db.mongoose.Schema(
  {
    user_id: {
      type: db.mongoose.Schema.Types.ObjectId,
      ref: "userModel",
      required: true,
    },
    shop_id: {
      type: db.mongoose.Schema.Types.ObjectId,
      ref: "shopModel",
      required: true,
    },
    product_id: {
      type: db.mongoose.Schema.Types.ObjectId,
      ref: "productModel",
      default: null,
    },
    order_id: {
      type: db.mongoose.Schema.Types.ObjectId,
      ref: "orderModel",
      required: true,
    },
    rating: { type: Number, required: true, min: 1, max: 5 },
    comment: { type: String, default: null },
    images: { type: [String], default: [] },
    status: {
      type: String,
      required: true,
      enum: ["visible", "hidden"],
      default: "visible",
    },
    deleted_at: { type: Date, default: null },
  },
  { collection: "reviews", timestamps: true },
);

let reviewModel = db.mongoose.model("reviewModel", reviewSchema);
module.exports = { reviewModel };
