const db = require("../configs/db");

const bannerSchema = new db.mongoose.Schema(
  {
    title: { type: String, required: true },
    image: { type: String, required: true },
    link_url: { type: String, default: null },
    sort_order: { type: Number, required: true, default: 0 },
    status: {
      type: String,
      required: true,
      enum: ["active", "inactive"],
      default: "active",
    },
    start_date: { type: Date, default: null },
    end_date: { type: Date, default: null },
    deleted_at: { type: Date, default: null },
  },
  { collection: "banners", timestamps: true },
);

let bannerModel = db.mongoose.model("bannerModel", bannerSchema);
module.exports = { bannerModel };
