const mongoose = require("mongoose");
const { cartModel } = require("../models/cart.model");
const { cartItemModel } = require("../models/cartItem.model");
const { productModel } = require("../models/product.model");
const { productVariantModel } = require("../models/productVariant.model");
const { productOptionModel } = require("../models/productOption.model");
const { userModel } = require("../models/user.model");
const { shopModel } = require("../models/shop.model");

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

    const { product_id, variant_id, selected_options, quantity, note, replace_cart } = req.body;

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

    // Giỏ hàng chỉ được chứa sản phẩm của 1 chi nhánh tại 1 thời điểm (giống
    // Grab/Shopee Food) — nếu giỏ đang có sản phẩm của chi nhánh khác thì
    // chặn lại, trừ khi client xác nhận muốn thay thế giỏ hàng (replace_cart).
    const activeCart = await getOrCreateActiveCart(user._id);
    const otherShopItem = await cartItemModel.findOne({
      cart_id: activeCart._id,
      deleted_at: null,
      shop_id: { $ne: product.shop_id },
    });
    if (otherShopItem) {
      if (!replace_cart) {
        const currentShop = await shopModel.findById(otherShopItem.shop_id);
        dataRes.status = "conflict";
        dataRes.code = "SHOP_CONFLICT";
        dataRes.msg = `Giỏ hàng của bạn đang có sản phẩm từ "${currentShop ? currentShop.shop_name : "cửa hàng khác"}"`;
        dataRes.data = {
          current_shop_id: String(otherShopItem.shop_id),
          current_shop_name: currentShop ? currentShop.shop_name : null,
        };
        return res.status(409).json(dataRes);
      }
      await cartItemModel.deleteMany({ cart_id: activeCart._id });
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

    // Look for existing item with exact same variant and options in active cart
    // Options compare: sorted option_ids match
    const existingItems = await cartItemModel.find({ cart_id: activeCart._id, product_id, variant_id, deleted_at: null });
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
        cart_id: activeCart._id,
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

    const newTotal = await recalculateCartTotal(activeCart._id);
    const items = await cartItemModel.find({ cart_id: activeCart._id, deleted_at: null });

    dataRes.status = "success";
    dataRes.data = {
      cart_id: activeCart._id,
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

exports.clearCart = async (req, res) => {
  const dataRes = { status: "error", msg: "" };
  try {
    const user = await findCurrentUser(req);
    if (!user) {
      dataRes.msg = "Không tìm thấy user";
      return res.status(404).json(dataRes);
    }

    const cart = await getOrCreateActiveCart(user._id);
    await cartItemModel.deleteMany({ cart_id: cart._id });
    cart.cart_total = 0;
    await cart.save();

    dataRes.status = "success";
    dataRes.data = { cart_id: cart._id, cart_total: 0, items: [] };
    return res.json(dataRes);
  } catch (err) {
    console.error("Clear cart error:", err);
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

exports.getSwitchShopOptions = async (req, res) => {
  const dataRes = { status: "error", msg: "" };
  try {
    const user = await findCurrentUser(req);
    if (!user) {
      dataRes.msg = "Không tìm thấy user";
      return res.status(404).json(dataRes);
    }

    const { product_id } = req.body;
    if (!product_id || !mongoose.Types.ObjectId.isValid(product_id)) {
      dataRes.msg = "Thiếu hoặc sai product_id";
      return res.status(400).json(dataRes);
    }

    const newProduct = await productModel.findOne({ _id: product_id, deleted_at: null, status: "active" });
    if (!newProduct) {
      dataRes.msg = "Sản phẩm không khả dụng";
      return res.status(400).json(dataRes);
    }

    const activeCart = await getOrCreateActiveCart(user._id);
    const cartItems = await cartItemModel.find({ cart_id: activeCart._id, deleted_at: null });

    const requiredNames = [...new Set(cartItems.map(item => item.product_name).concat(newProduct.product_name))];

    // Find valid, active, non-blocked shops that have products for ALL requiredNames
    const activeProductShopIds = await productModel.distinct("shop_id", { status: "active", deleted_at: null });
    const shops = await shopModel.find({
      _id: { $in: activeProductShopIds },
      status: "active",
      deleted_at: null
    }).populate("owner_user_id");

    const validShops = shops.filter(shop => {
      const owner = shop.owner_user_id;
      return owner && owner.status !== "blocked" && owner.deleted_at === null;
    });

    const candidateShops = [];
    for (const shop of validShops) {
      const shopProductsCount = await productModel.countDocuments({
        shop_id: shop._id,
        product_name: { $in: requiredNames },
        status: "active",
        deleted_at: null
      });
      if (shopProductsCount === requiredNames.length) {
        candidateShops.push(shop);
      }
    }

    if (candidateShops.length === 0) {
      dataRes.msg = "Các sản phẩm hiện có trong giỏ hàng và sản phẩm bạn vừa chọn không được bán đồng thời tại bất kỳ cửa hàng nào khác.";
      return res.status(400).json(dataRes);
    }

    dataRes.status = "success";
    dataRes.data = candidateShops.map(shop => {
      const logoFile = shop.logo ? shop.logo.split("/").pop() : "default_avatar.jpg";
      const bannerFile = shop.banner ? shop.banner.split("/").pop() : "default_banner.jpg";
      const shopObj = { ...shop._doc };
      delete shopObj.avatar;
      delete shopObj.owner_user_id;
      if (shopObj.total_reviews === 0) {
        shopObj.rating_average = 99;
      }
      return {
        ...shopObj,
        logo: `${req.protocol}://${req.get("host")}/images/shops/${logoFile}`,
        banner: `${req.protocol}://${req.get("host")}/images/shops/${bannerFile}`,
      };
    });

    return res.json(dataRes);
  } catch (err) {
    console.error("getSwitchShopOptions error:", err);
    dataRes.msg = "Server error: " + err.message;
    return res.status(500).json(dataRes);
  }
};

exports.switchShop = async (req, res) => {
  const dataRes = { status: "error", msg: "" };
  try {
    const user = await findCurrentUser(req);
    if (!user) {
      dataRes.msg = "Không tìm thấy user";
      return res.status(404).json(dataRes);
    }

    const { shop_id, product_id, variant_id, selected_options, quantity } = req.body;
    if (!shop_id || !mongoose.Types.ObjectId.isValid(shop_id) ||
        !product_id || !mongoose.Types.ObjectId.isValid(product_id) ||
        !variant_id || !mongoose.Types.ObjectId.isValid(variant_id) ||
        !quantity || quantity <= 0) {
      dataRes.msg = "Dữ liệu chuyển đổi shop không hợp lệ";
      return res.status(400).json(dataRes);
    }

    const targetShop = await shopModel.findOne({ _id: shop_id, status: "active", deleted_at: null });
    if (!targetShop) {
      dataRes.msg = "Cửa hàng không tồn tại hoặc đã ngừng hoạt động";
      return res.status(404).json(dataRes);
    }

    const activeCart = await getOrCreateActiveCart(user._id);
    const cartItems = await cartItemModel.find({ cart_id: activeCart._id, deleted_at: null });

    // 1. Map existing cart items to the new shop's corresponding products, variants and options
    for (const item of cartItems) {
      const targetProduct = await productModel.findOne({
        shop_id: shop_id,
        product_name: item.product_name,
        status: "active",
        deleted_at: null
      });
      if (!targetProduct) {
        dataRes.msg = `Sản phẩm "${item.product_name}" không có sẵn tại cửa hàng mới`;
        return res.status(400).json(dataRes);
      }

      const targetVariant = await productVariantModel.findOne({
        product_id: targetProduct._id,
        variant_name: item.variant_name,
        status: "active",
        deleted_at: null
      });
      if (!targetVariant) {
        dataRes.msg = `Phiên bản "${item.variant_name}" của "${item.product_name}" không có sẵn tại cửa hàng mới`;
        return res.status(400).json(dataRes);
      }

      let basePrice = targetVariant.price;
      if (targetVariant.sale_price !== null && targetVariant.sale_price !== undefined) {
        basePrice = targetVariant.sale_price;
      }

      let optionTotalPrice = 0;
      const verifiedOptions = [];
      if (Array.isArray(item.selected_options) && item.selected_options.length > 0) {
        for (const opt of item.selected_options) {
          const optionDoc = await productOptionModel.findOne({
            product_id: targetProduct._id,
            option_name: opt.option_name,
            status: "active",
            deleted_at: null
          });
          if (!optionDoc) {
            dataRes.msg = `Tùy chọn "${opt.option_name}" không có sẵn tại cửa hàng mới`;
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

      item.shop_id = targetShop._id;
      item.product_id = targetProduct._id;
      item.variant_id = targetVariant._id;
      item.product_image = targetVariant.image || null;
      item.base_price = basePrice;
      item.selected_options = verifiedOptions;
      item.option_total_price = optionTotalPrice;
      item.unit_price = unitPrice;
      item.subtotal = unitPrice * item.quantity;

      await item.save();
    }

    // 2. Add the new product
    const product = await productModel.findOne({ _id: product_id, deleted_at: null, status: "active" });
    if (!product) {
      dataRes.msg = "Sản phẩm mới không khả dụng";
      return res.status(400).json(dataRes);
    }
    if (String(product.shop_id) !== String(shop_id)) {
      dataRes.msg = "Sản phẩm không thuộc cửa hàng đã chọn";
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

    const existingItems = await cartItemModel.find({ cart_id: activeCart._id, product_id, variant_id, deleted_at: null });
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
      matchedItem.quantity += quantity;
      matchedItem.subtotal = matchedItem.quantity * matchedItem.unit_price;
      await matchedItem.save();
    } else {
      await cartItemModel.create({
        cart_id: activeCart._id,
        product_id,
        variant_id,
        shop_id: targetShop._id,
        quantity,
        product_name: product.product_name,
        variant_name: variant.variant_name,
        product_image: variant.image || null,
        base_price: basePrice,
        selected_options: verifiedOptions,
        option_total_price: optionTotalPrice,
        unit_price: unitPrice,
        subtotal: unitPrice * quantity,
      });
    }

    const newTotal = await recalculateCartTotal(activeCart._id);
    const items = await cartItemModel.find({ cart_id: activeCart._id, deleted_at: null });

    dataRes.status = "success";
    dataRes.data = {
      cart_id: activeCart._id,
      cart_total: newTotal,
      items: formatCartItems(items, req),
    };
    return res.json(dataRes);
  } catch (err) {
    console.error("switchShop error:", err);
    dataRes.msg = "Server error: " + err.message;
    return res.status(500).json(dataRes);
  }
};
