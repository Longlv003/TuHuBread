const db = require("../configs/db");

const productAttributeSchema = new db.mongoose.Schema(
  {
    product_id: {
      type: db.mongoose.Schema.Types.ObjectId,
      ref: "productModel",
      required: true,
    },
    attribute_key: { type: String, required: true },
    attribute_label: { type: String, required: true },
    attribute_value: { type: String, required: true },
    sort_order: { type: Number, required: true, default: 0 },
    status: {
      type: String,
      required: true,
      enum: ["active", "inactive"],
      default: "active",
    },
    deleted_at: { type: Date, default: null },
  },
  { collection: "product_attributes", timestamps: true },
);

let productAttributeModel = db.mongoose.model(
  "productAttributeModel",
  productAttributeSchema,
);
module.exports = { productAttributeModel };
