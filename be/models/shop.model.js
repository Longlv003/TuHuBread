const db = require("../configs/db");

const shopSchema = new db.mongoose.Schema(
  {
    owner_user_id: {
      type: db.mongoose.Schema.Types.ObjectId,
      ref: "userModel",
      required: true,
    },
    shop_name: { type: String, required: true },
    shop_slug: { type: String, required: true, unique: true },
    logo: { type: String, default: null },
    banner: { type: String, default: null },
    phone_number: { type: String, required: true },
    address: { type: String, required: true },
    location: {
      type: {
        type: String,
        enum: ["Point"],
        required: true,
        default: "Point",
      },
      coordinates: {
        type: [Number], // [longitude, latitude]
        required: true,
      },
    },
    rating_average: { type: Number, required: true, default: 0 },
    total_reviews: { type: Number, required: true, default: 0 },
    open_time: { type: String, default: null },
    close_time: { type: String, default: null },
    is_open: { type: Boolean, required: true, default: false },
    status: {
      type: String,
      required: true,
      enum: ["pending", "active", "inactive", "banned"],
      default: "pending",
    },
    deleted_at: { type: Date, default: null },
  },
  { collection: "shops", timestamps: true },
);

// Index for geo-spatial queries
shopSchema.index({ location: "2dsphere" });

let shopModel = db.mongoose.model("shopModel", shopSchema);
module.exports = { shopModel };
