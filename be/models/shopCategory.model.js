const db = require("../configs/db");

const shopCategorySchema = new db.mongoose.Schema(
  {
    shop_id: {
      type: db.mongoose.Schema.Types.ObjectId,
      ref: "shopModel",
      required: true,
    },
    category_name: { type: String, required: true },
    category_slug: { type: String, required: true },
    sort_order: { type: Number, required: true, default: 0 },
    status: {
      type: String,
      required: true,
      enum: ["active", "inactive"],
      default: "active",
    },
    deleted_at: { type: Date, default: null },
  },
  { collection: "shop_categories", timestamps: true },
);

let shopCategoryModel = db.mongoose.model(
  "shopCategoryModel",
  shopCategorySchema,
);
module.exports = { shopCategoryModel };
