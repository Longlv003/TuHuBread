const db = require("../configs/db");

const productVariantSchema = new db.mongoose.Schema(
  {
    product_id: {
      type: db.mongoose.Schema.Types.ObjectId,
      ref: "productModel",
      required: true,
    },
    variant_name: { type: String, required: true },
    variant_slug: { type: String, required: true },
    image: { type: String, default: null },
    price: { type: Number, required: true },
    sale_price: { type: Number, default: null },
    stock_quantity: { type: Number, required: true, default: 0 },
    sold_quantity: { type: Number, required: true, default: 0 },
    status: {
      type: String,
      required: true,
      enum: ["active", "inactive", "out_of_stock"],
      default: "active",
    },
    deleted_at: { type: Date, default: null },
  },
  { collection: "product_variants", timestamps: true },
);

let productVariantModel = db.mongoose.model(
  "productVariantModel",
  productVariantSchema,
);
module.exports = { productVariantModel };
