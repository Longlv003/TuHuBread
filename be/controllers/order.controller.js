const mongoose = require("mongoose");
const { orderModel } = require("../models/order.model");
const { orderDetailModel } = require("../models/orderDetail.model");
const { userModel } = require("../models/user.model");
const { shopModel } = require("../models/shop.model");
const { productModel } = require("../models/product.model");
const { productVariantModel } = require("../models/productVariant.model");
const { addressModel } = require("../models/address.model");

const DELIVERY_FEES = {
  priority: 25000,
  standard: 15000,
  saving: 0,
};

const PAYMENT_METHODS = ["cash", "momo", "zalopay"];

async function findCurrentUser(req) {
  return userModel.findOne({ firebase_uid: req.user.uid });
}

function generateOrderCode() {
  const time = Date.now().toString(36).toUpperCase();
  const rand = Math.random().toString(36).slice(2, 6).toUpperCase();
  return `TH${time}${rand}`;
}

exports.getOrders = async (req, res) => {
  let dataRes = { msg: "OK", data: null };
  try {
    const { uid } = req.user; // từ middleware firebaseAuth
    const user = await userModel.findOne({ firebase_uid: uid });
    if (!user) {
      dataRes.msg = "User not found";
      return res.status(404).json(dataRes);
    }

    let orders = await orderModel.find({ user_id: user._id, deleted_at: null })
      .populate("shop_id")
      .sort({ createdAt: -1 });



    dataRes.data = orders.map(order => {
      const shopLogo = order.shop_id?.logo
        ? (order.shop_id.logo.startsWith("http")
            ? order.shop_id.logo
            : `${req.protocol}://${req.get("host")}/images/shops/${order.shop_id.logo.split("/").pop()}`)
        : null;

      return {
        ...order.toObject(),
        shop: order.shop_id ? {
          shop_name: order.shop_id.shop_name,
          logo: shopLogo
        } : null
      };
    });

  } catch (err) {
    console.error("getOrders error:", err.message);
    dataRes.msg = "Server error: " + err.message;
    return res.status(500).json(dataRes);
  }
  return res.json(dataRes);
};

exports.getOrderById = async (req, res) => {
  let dataRes = { msg: "OK", data: null };
  try {
    const { id } = req.params;
    const { uid } = req.user;

    const user = await userModel.findOne({ firebase_uid: uid });
    if (!user) {
      dataRes.msg = "User not found";
      return res.status(404).json(dataRes);
    }

    const order = await orderModel.findOne({ _id: id, user_id: user._id, deleted_at: null })
      .populate("shop_id")
      .populate("address_id");

    if (!order) {
      dataRes.msg = "Order not found";
      return res.status(404).json(dataRes);
    }

    const items = await orderDetailModel.find({ order_id: order._id });

    const shopLogo = order.shop_id?.logo
      ? (order.shop_id.logo.startsWith("http")
          ? order.shop_id.logo
          : `${req.protocol}://${req.get("host")}/images/shops/${order.shop_id.logo.split("/").pop()}`)
      : null;

    dataRes.data = {
      order: {
        ...order.toObject(),
        shop: order.shop_id ? {
          shop_name: order.shop_id.shop_name,
          logo: shopLogo,
          phone: order.shop_id.phone_number
        } : null
      },
      items: items.map(item => {
        const itemImage = item.product_image
          ? (item.product_image.startsWith("http")
              ? item.product_image
              : `${req.protocol}://${req.get("host")}/images/products/${item.product_image.split("/").pop()}`)
          : null;
        return {
          ...item.toObject(),
          product_image: itemImage
        };
      })
    };

  } catch (err) {
    console.error("getOrderById error:", err.message);
    dataRes.msg = "Server error: " + err.message;
    return res.status(500).json(dataRes);
  }
  return res.json(dataRes);
};

exports.cancelOrder = async (req, res) => {
  let dataRes = { msg: "OK", data: null };
  try {
    const { id } = req.params;
    const { uid } = req.user;

    const user = await userModel.findOne({ firebase_uid: uid });
    if (!user) {
      dataRes.msg = "User not found";
      return res.status(404).json(dataRes);
    }

    const order = await orderModel.findOne({ _id: id, user_id: user._id, deleted_at: null });
    if (!order) {
      dataRes.msg = "Order not found";
      return res.status(404).json(dataRes);
    }

    if (order.order_status !== "pending" && order.order_status !== "confirmed") {
      dataRes.msg = "Chỉ có thể hủy đơn hàng ở trạng thái chờ xác nhận hoặc đã xác nhận";
      return res.status(400).json(dataRes);
    }

    order.order_status = "cancelled";
    await order.save();

    dataRes.msg = "Hủy đơn hàng thành công";
    dataRes.data = order;

  } catch (err) {
    console.error("cancelOrder error:", err.message);
    dataRes.msg = "Server error: " + err.message;
    return res.status(500).json(dataRes);
  }
  return res.json(dataRes);
};

// POST /api/orders
exports.createOrder = async (req, res) => {
  let dataRes = { msg: "OK", data: null };

  try {
    const user = await findCurrentUser(req);
    if (!user) {
      dataRes.msg = "Không tìm thấy user";
      return res.status(404).json(dataRes);
    }

    const { address_id, delivery_option, payment_method, note, items } = req.body;

    if (!address_id || !mongoose.Types.ObjectId.isValid(address_id)) {
      dataRes.msg = "Thiếu hoặc sai địa chỉ giao hàng";
      return res.status(400).json(dataRes);
    }

    if (!DELIVERY_FEES.hasOwnProperty(delivery_option)) {
      dataRes.msg = "Tùy chọn giao hàng không hợp lệ";
      return res.status(400).json(dataRes);
    }

    if (!PAYMENT_METHODS.includes(payment_method)) {
      dataRes.msg = "Phương thức thanh toán không hợp lệ";
      return res.status(400).json(dataRes);
    }

    if (!Array.isArray(items) || items.length === 0) {
      dataRes.msg = "Giỏ hàng trống";
      return res.status(400).json(dataRes);
    }

    const address = await addressModel.findOne({
      _id: address_id,
      user_id: user._id,
      deleted_at: null,
    });
    if (!address) {
      dataRes.msg = "Không tìm thấy địa chỉ giao hàng";
      return res.status(404).json(dataRes);
    }

    for (const item of items) {
      if (
        !item.product_id ||
        !mongoose.Types.ObjectId.isValid(item.product_id) ||
        !item.variant_id ||
        !mongoose.Types.ObjectId.isValid(item.variant_id) ||
        !item.shop_id ||
        !mongoose.Types.ObjectId.isValid(item.shop_id) ||
        !item.quantity ||
        item.quantity <= 0 ||
        typeof item.unit_price !== "number" ||
        item.unit_price < 0
      ) {
        dataRes.msg = "Dữ liệu sản phẩm trong giỏ hàng không hợp lệ";
        return res.status(400).json(dataRes);
      }
    }

    // Order model chỉ hỗ trợ 1 shop/đơn — gộp giỏ hàng theo shop_id, mỗi
    // shop tạo 1 đơn riêng. Phí giao hàng được tính 1 lần cho đơn đầu tiên.
    const itemsByShop = new Map();
    for (const item of items) {
      const key = String(item.shop_id);
      if (!itemsByShop.has(key)) itemsByShop.set(key, []);
      itemsByShop.get(key).push(item);
    }

    const deliveryFee = DELIVERY_FEES[delivery_option];
    const createdOrders = [];
    let shopIndex = 0;

    for (const [shopId, shopItems] of itemsByShop) {
      const itemsTotal = shopItems.reduce(
        (sum, it) => sum + it.unit_price * it.quantity,
        0,
      );
      const shopDeliveryFee = shopIndex === 0 ? deliveryFee : 0;
      const totalAmount = itemsTotal + shopDeliveryFee;

      const order = await orderModel.create({
        order_code: generateOrderCode(),
        user_id: user._id,
        shop_id: shopId,
        address_id: address._id,
        payment_method,
        delivery_option,
        items_total: itemsTotal,
        discount_amount: 0,
        delivery_fee: shopDeliveryFee,
        total_amount: totalAmount,
        note: note || null,
      });

      await orderDetailModel.insertMany(
        shopItems.map((it) => ({
          order_id: order._id,
          product_id: it.product_id,
          variant_id: it.variant_id,
          quantity: it.quantity,
          product_name: it.product_name,
          variant_name: it.variant_name,
          product_image: it.product_image || null,
          base_price: it.unit_price,
          selected_options: it.selected_options || [],
          option_total_price: 0,
          unit_price: it.unit_price,
          subtotal: it.unit_price * it.quantity,
        })),
      );

      createdOrders.push({
        order_id: order._id,
        order_code: order.order_code,
        shop_id: shopId,
        items_total: itemsTotal,
        delivery_fee: shopDeliveryFee,
        total_amount: totalAmount,
      });

      shopIndex += 1;
    }

    dataRes.data = {
      orders: createdOrders,
      total_amount: createdOrders.reduce((sum, o) => sum + o.total_amount, 0),
    };
    return res.json(dataRes);
  } catch (err) {
    console.error("Create order error:", err.message);
    dataRes.msg = "Server error: " + err.message;
    return res.status(500).json(dataRes);
  }
};

