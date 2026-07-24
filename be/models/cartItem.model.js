const db = require("../configs/db");

const cartItemSchema = new db.mongoose.Schema(
  {
    cart_id: {
      type: db.mongoose.Schema.Types.ObjectId,
      ref: "cartModel",
      required: true,
    },
    product_id: {
      type: db.mongoose.Schema.Types.ObjectId,
      ref: "productModel",
      required: true,
    },
    variant_id: {
      type: db.mongoose.Schema.Types.ObjectId,
      ref: "productVariantModel",
      required: true,
    },
    shop_id: {
      type: db.mongoose.Schema.Types.ObjectId,
      ref: "shopModel",
      required: true,
    },
    quantity: { type: Number, required: true, default: 1 },
    product_name: { type: String, required: true },
    variant_name: { type: String, required: true },
    product_image: { type: String, default: null },
    base_price: { type: Number, required: true },
    selected_options: { type: Array, default: [] },
    option_total_price: { type: Number, required: true, default: 0 },
    unit_price: { type: Number, required: true },
    subtotal: { type: Number, required: true },
  },
  { collection: "cart_items", timestamps: true },
);

let cartItemModel = db.mongoose.model("cartItemModel", cartItemSchema);
module.exports = { cartItemModel };
