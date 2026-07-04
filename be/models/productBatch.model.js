const db = require("../configs/db");

const productBatchSchema = new db.mongoose.Schema(
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
    batch_code: { type: String, required: true },
    quantity_imported: { type: Number, required: true, default: 0 },
    quantity_remaining: { type: Number, required: true, default: 0 },
    production_date: { type: Date, required: true },
    expired_at: { type: Date, required: true },
    status: {
      type: String,
      required: true,
      enum: ["active", "expired", "sold_out"],
      default: "active",
    },
    deleted_at: { type: Date, default: null },
  },
  { collection: "product_batches", timestamps: true },
);

let productBatchModel = db.mongoose.model(
  "productBatchModel",
  productBatchSchema,
);
module.exports = { productBatchModel };
