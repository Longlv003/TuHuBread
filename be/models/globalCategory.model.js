const db = require("../configs/db");

const globalCategorySchema = new db.mongoose.Schema(
  {
    category_name: { type: String, required: true },
    category_slug: { type: String, required: true, unique: true },
    category_icon: { type: String, default: null },
    status: {
      type: String,
      required: true,
      enum: ["active", "inactive"],
      default: "active",
    },
    deleted_at: { type: Date, default: null },
  },
  { collection: "global_categories", timestamps: true },
);

let globalCategoryModel = db.mongoose.model(
  "globalCategoryModel",
  globalCategorySchema,
);
module.exports = { globalCategoryModel };
