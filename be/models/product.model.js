const db = require("../configs/db");

const productSchema = new db.mongoose.Schema(
  {
    shop_id: {
      type: db.mongoose.Schema.Types.ObjectId,
      ref: "shopModel",
      required: true,
    },
    global_category_id: {
      type: db.mongoose.Schema.Types.ObjectId,
      ref: "globalCategoryModel",
      required: true,
    },
    shop_category_id: {
      type: db.mongoose.Schema.Types.ObjectId,
      ref: "shopCategoryModel",
      default: null,
    },
    product_name: { type: String, required: true },
    product_slug: { type: String, required: true },
    description: { type: String, default: null },
    preparation_time_minutes: { type: Number, required: true, default: 0 },
    status: {
      type: String,
      required: true,
      enum: ["active", "inactive", "out_of_stock"],
      default: "active",
    },
    deleted_at: { type: Date, default: null },
  },
  { collection: "products", timestamps: true },
);

let productModel = db.mongoose.model("productModel", productSchema);
module.exports = { productModel };
