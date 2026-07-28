const mongoose = require("mongoose");
const { cartModel } = require("../models/cart.model");
const { cartItemModel } = require("../models/cartItem.model");
const { productModel } = require("../models/product.model");
const { productVariantModel } = require("../models/productVariant.model");
const { productOptionModel } = require("../models/productOption.model");
const { userModel } = require("../models/user.model");

async function findCurrentUser(req) {
  return userModel.findOne({ firebase_uid: req.user.uid });
}

// Get or create active cart for user
async function getOrCreateActiveCart(userId) {
  let cart = await cartModel.findOne({ user_id: userId, status: "active", deleted_at: null });
  if (!cart) {
    cart = await cartModel.create({ user_id: userId, status: "active", cart_total: 0 });
  }
  return cart;
}

// Recalculate cart total
async function recalculateCartTotal(cartId) {
  const items = await cartItemModel.find({ cart_id: cartId, deleted_at: null });
  const total = items.reduce((sum, item) => sum + item.subtotal, 0);
  await cartModel.findByIdAndUpdate(cartId, { cart_total: total });
  return total;
}

// Format product_image in cart items to absolute URL (same pattern as product.controller.js)
function formatCartItems(items, req) {
  return items.map((item) => {
    const obj = item.toObject ? item.toObject() : item;
    if (obj.product_image) {
      const isAbsolute = obj.product_image.startsWith("http");
      if (!isAbsolute) {
        const fileName = obj.product_image.split("/").pop();
        obj.product_image = `${req.protocol}://${req.get("host")}/images/products/${fileName}`;
      }
    }
    return obj;
  });
}

exports.getCart = async (req, res) => {
  const dataRes = { status: "error", msg: "" };
  try {
    const user = await findCurrentUser(req);
    if (!user) {
      dataRes.msg = "Không tìm thấy user";
      return res.status(404).json(dataRes);
    }

    const cart = await getOrCreateActiveCart(user._id);
    const items = await cartItemModel.find({ cart_id: cart._id, deleted_at: null });

    dataRes.status = "success";
    dataRes.data = {
      cart_id: cart._id,
      cart_total: cart.cart_total,
      items: formatCartItems(items, req),
    };
    return res.json(dataRes);
  } catch (err) {
    console.error("Get cart error:", err);
    dataRes.msg = "Server error: " + err.message;
    return res.status(500).json(dataRes);
  }
};

exports.addToCart = async (req, res) => {
  const dataRes = { status: "error", msg: "" };
  try {
    const user = await findCurrentUser(req);
    if (!user) {
      dataRes.msg = "Không tìm thấy user";
      return res.status(404).json(dataRes);
    }

    const { product_id, variant_id, selected_options, quantity, note } = req.body;

    if (!product_id || !mongoose.Types.ObjectId.isValid(product_id) ||
        !variant_id || !mongoose.Types.ObjectId.isValid(variant_id) ||
        !quantity || quantity <= 0) {
      dataRes.msg = "Dữ liệu thêm vào giỏ hàng không hợp lệ";
      return res.status(400).json(dataRes);
    }

    // Validate product & variant exist & active
    const product = await productModel.findOne({ _id: product_id, deleted_at: null, status: "active" });
    if (!product) {
      dataRes.msg = "Sản phẩm không khả dụng";
      return res.status(400).json(dataRes);
    }

    const variant = await productVariantModel.findOne({ _id: variant_id, product_id, deleted_at: null, status: "active" });
    if (!variant) {
      dataRes.msg = "Phiên bản sản phẩm không khả dụng";
      return res.status(400).json(dataRes);
    }

    let basePrice = variant.price;
    if (variant.sale_price !== null && variant.sale_price !== undefined) {
      basePrice = variant.sale_price;
    }

    // Validate options
    let optionTotalPrice = 0;
    const verifiedOptions = [];
    if (Array.isArray(selected_options) && selected_options.length > 0) {
      for (const opt of selected_options) {
        const optId = opt.option_id || opt._id;
        const optionDoc = await productOptionModel.findOne({ _id: optId, product_id, deleted_at: null, status: "active" });
        if (!optionDoc) {
          dataRes.msg = "Tùy chọn sản phẩm không khả dụng";
          return res.status(400).json(dataRes);
        }
        optionTotalPrice += optionDoc.extra_price;
        verifiedOptions.push({
          option_id: optionDoc._id,
          option_name: optionDoc.option_name,
          extra_price: optionDoc.extra_price,
        });
      }
    }

    const unitPrice = basePrice + optionTotalPrice;
    const cart = await getOrCreateActiveCart(user._id);

    // Look for existing item with exact same variant and options in active cart
    // Options compare: sorted option_ids match
    const existingItems = await cartItemModel.find({ cart_id: cart._id, product_id, variant_id, deleted_at: null });
    let matchedItem = null;

    const targetOptIds = verifiedOptions.map(o => String(o.option_id)).sort().join(",");

    for (const item of existingItems) {
      const itemOptIds = (item.selected_options || []).map(o => String(o.option_id || o._id)).sort().join(",");
      if (itemOptIds === targetOptIds) {
        matchedItem = item;
        break;
      }
    }

    if (matchedItem) {
      // Increment quantity
      matchedItem.quantity += quantity;
      matchedItem.subtotal = matchedItem.quantity * matchedItem.unit_price;
      if (note !== undefined) matchedItem.note = note;
      await matchedItem.save();
    } else {
      // Create new cart item
      await cartItemModel.create({
        cart_id: cart._id,
        product_id,
        variant_id,
        shop_id: product.shop_id,
        quantity,
        product_name: product.product_name,
        variant_name: variant.variant_name,
        product_image: variant.image || null,
        base_price: basePrice,
        selected_options: verifiedOptions,
        option_total_price: optionTotalPrice,
        unit_price: unitPrice,
        subtotal: unitPrice * quantity,
        note: note || null,
      });
    }

    const newTotal = await recalculateCartTotal(cart._id);
    const items = await cartItemModel.find({ cart_id: cart._id, deleted_at: null });

    dataRes.status = "success";
    dataRes.data = {
      cart_id: cart._id,
      cart_total: newTotal,
      items: formatCartItems(items, req),
    };
    return res.json(dataRes);
  } catch (err) {
    console.error("Add to cart error:", err);
    dataRes.msg = "Server error: " + err.message;
    return res.status(500).json(dataRes);
  }
};

exports.updateCartItem = async (req, res) => {
  const dataRes = { status: "error", msg: "" };
  try {
    const user = await findCurrentUser(req);
    if (!user) {
      dataRes.msg = "Không tìm thấy user";
      return res.status(404).json(dataRes);
    }

    const { itemId } = req.params;
    const { quantity, note } = req.body;

    if (!itemId || !mongoose.Types.ObjectId.isValid(itemId) || !quantity || quantity <= 0) {
      dataRes.msg = "Dữ liệu cập nhật không hợp lệ";
      return res.status(400).json(dataRes);
    }

    const cart = await getOrCreateActiveCart(user._id);
    const item = await cartItemModel.findOne({ _id: itemId, cart_id: cart._id, deleted_at: null });
    if (!item) {
      dataRes.msg = "Không tìm thấy sản phẩm trong giỏ hàng";
      return res.status(404).json(dataRes);
    }

    item.quantity = quantity;
    item.subtotal = quantity * item.unit_price;
    if (note !== undefined) {
      item.note = note;
    }
    await item.save();

    const newTotal = await recalculateCartTotal(cart._id);
    const items = await cartItemModel.find({ cart_id: cart._id, deleted_at: null });

    dataRes.status = "success";
    dataRes.data = {
      cart_id: cart._id,
      cart_total: newTotal,
      items: formatCartItems(items, req),
    };
    return res.json(dataRes);
  } catch (err) {
    console.error("Update cart item error:", err);
    dataRes.msg = "Server error: " + err.message;
    return res.status(500).json(dataRes);
  }
};

exports.deleteCartItem = async (req, res) => {
  const dataRes = { status: "error", msg: "" };
  try {
    const user = await findCurrentUser(req);
    if (!user) {
      dataRes.msg = "Không tìm thấy user";
      return res.status(404).json(dataRes);
    }

    const { itemId } = req.params;
    if (!itemId || !mongoose.Types.ObjectId.isValid(itemId)) {
      dataRes.msg = "ID sản phẩm không hợp lệ";
      return res.status(400).json(dataRes);
    }

    const cart = await getOrCreateActiveCart(user._id);
    const item = await cartItemModel.findOne({ _id: itemId, cart_id: cart._id, deleted_at: null });
    if (!item) {
      dataRes.msg = "Không tìm thấy sản phẩm trong giỏ hàng";
      return res.status(404).json(dataRes);
    }

    // Hard delete cart item
    await cartItemModel.deleteOne({ _id: itemId, cart_id: cart._id });

    const newTotal = await recalculateCartTotal(cart._id);
    const items = await cartItemModel.find({ cart_id: cart._id, deleted_at: null });

    dataRes.status = "success";
    dataRes.data = {
      cart_id: cart._id,
      cart_total: newTotal,
      items: formatCartItems(items, req),
    };
    return res.json(dataRes);
  } catch (err) {
    console.error("Delete cart item error:", err);
    dataRes.msg = "Server error: " + err.message;
    return res.status(500).json(dataRes);
  }
};
