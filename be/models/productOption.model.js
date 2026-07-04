const db = require("../configs/db");

const productOptionSchema = new db.mongoose.Schema(
  {
    product_id: {
      type: db.mongoose.Schema.Types.ObjectId,
      ref: "productModel",
      required: true,
    },
    option_name: { type: String, required: true },
    option_slug: { type: String, required: true },
    extra_price: { type: Number, required: true, default: 0 },
    status: {
      type: String,
      required: true,
      enum: ["active", "inactive", "out_of_stock"],
      default: "active",
    },
    deleted_at: { type: Date, default: null },
  },
  { collection: "product_options", timestamps: true },
);

let productOptionModel = db.mongoose.model(
  "productOptionModel",
  productOptionSchema,
);
module.exports = { productOptionModel };
