const db = require("../configs/db");

const productSaleSchema = new db.mongoose.Schema(
  {
    product_id: {
      type: db.mongoose.Schema.Types.ObjectId,
      ref: "productModel",
      required: true,
    },
    variant_id: {
      type: db.mongoose.Schema.Types.ObjectId,
      ref: "productVariantModel",
      default: null,
    },
    sale_name: { type: String, required: true },
    sale_price: { type: Number, required: true },
    sale_limit: { type: Number, default: null },
    sold_quantity: { type: Number, required: true, default: 0 },
    start_date: { type: Date, required: true },
    end_date: { type: Date, required: true },
    status: {
      type: String,
      required: true,
      enum: ["active", "inactive", "expired"],
      default: "active",
    },
    deleted_at: { type: Date, default: null },
  },
  { collection: "product_sales", timestamps: true },
);

let productSaleModel = db.mongoose.model("productSaleModel", productSaleSchema);
module.exports = { productSaleModel };
