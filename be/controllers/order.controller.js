const mongoose = require("mongoose");
const { orderModel } = require("../models/order.model");
const { orderDetailModel } = require("../models/orderDetail.model");
const { userModel } = require("../models/user.model");
const { shopModel } = require("../models/shop.model");
const { productModel } = require("../models/product.model");
const { productVariantModel } = require("../models/productVariant.model");
const { addressModel } = require("../models/address.model");
const { voucherModel } = require("../models/voucher.model");
const { voucherSaveModel } = require("../models/voucherSave.model");


const DELIVERY_FEES = {
  priority: 25000,
  standard: 15000,
  saving: 0,
};

const PAYMENT_METHODS = ["cash", "vnpay"];

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

    const { address_id, delivery_option, payment_method, note, items, voucher_code } = req.body;

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

    const { productOptionModel } = require("../models/productOption.model");

    for (const item of items) {
      if (
        !item.product_id ||
        !mongoose.Types.ObjectId.isValid(item.product_id) ||
        !item.variant_id ||
        !mongoose.Types.ObjectId.isValid(item.variant_id) ||
        !item.shop_id ||
        !mongoose.Types.ObjectId.isValid(item.shop_id) ||
        !item.quantity ||
        item.quantity <= 0
      ) {
        dataRes.msg = "Dữ liệu sản phẩm trong giỏ hàng không hợp lệ";
        return res.status(400).json(dataRes);
      }

      const product = await productModel.findOne({
        _id: item.product_id,
        deleted_at: null,
        status: "active",
      });
      if (!product) {
        dataRes.msg = `Sản phẩm "${item.product_name || "không tên"}" không tồn tại hoặc đã ngừng bán`;
        return res.status(400).json(dataRes);
      }

      const variant = await productVariantModel.findOne({
        _id: item.variant_id,
        product_id: item.product_id,
        deleted_at: null,
        status: "active",
      });
      if (!variant) {
        dataRes.msg = `Phiên bản của sản phẩm "${item.product_name || "không tên"}" không tồn tại hoặc đã hết hàng`;
        return res.status(400).json(dataRes);
      }

      let variantPrice = variant.price;
      if (variant.sale_price !== null && variant.sale_price !== undefined) {
        variantPrice = variant.sale_price;
      }

      let optionTotalPrice = 0;
      const verifiedOptions = [];
      if (Array.isArray(item.selected_options) && item.selected_options.length > 0) {
        for (const opt of item.selected_options) {
          const optId = opt.option_id || opt._id;
          if (!optId || !mongoose.Types.ObjectId.isValid(optId)) {
            dataRes.msg = "Dữ liệu tùy chọn không hợp lệ";
            return res.status(400).json(dataRes);
          }
          const optionDoc = await productOptionModel.findOne({
            _id: optId,
            product_id: item.product_id,
            deleted_at: null,
            status: "active",
          });
          if (!optionDoc) {
            dataRes.msg = `Tùy chọn "${opt.option_name || "không tên"}" của sản phẩm không khả dụng`;
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

      item.base_price = variantPrice;
      item.option_total_price = optionTotalPrice;
      item.unit_price = variantPrice + optionTotalPrice;
      item.selected_options = verifiedOptions;
    }

    // Xử lý và tính toán Voucher nếu có truyền lên
    let appliedVoucher = null;
    let savedVoucherDoc = null;
    if (voucher_code) {
      savedVoucherDoc = await voucherSaveModel.findOne({
        user_id: user._id,
        voucher_code: voucher_code,
        status: "saved",
        expires_at: { $gt: new Date() }
      }).populate("voucher_id");

      if (!savedVoucherDoc || !savedVoucherDoc.voucher_id) {
        dataRes.msg = "Voucher không hợp lệ hoặc đã hết hạn";
        return res.status(400).json(dataRes);
      }

      appliedVoucher = savedVoucherDoc.voucher_id;
      const overallItemsTotal = items.reduce((sum, it) => sum + it.unit_price * it.quantity, 0);
      if (overallItemsTotal < appliedVoucher.minOrderAmount) {
        dataRes.msg = `Đơn hàng tối thiểu phải từ ${appliedVoucher.minOrderAmount}đ để sử dụng voucher này`;
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
    
    // Tính toán lượng giảm giá tổng của voucher
    let totalDiscount = 0;
    if (appliedVoucher) {
      const overallItemsTotal = items.reduce((sum, it) => sum + it.unit_price * it.quantity, 0);
      if (appliedVoucher.discountType === "free_shipping") {
        totalDiscount = deliveryFee;
      } else if (appliedVoucher.discountType === "percent") {
        let discount = overallItemsTotal * (appliedVoucher.discountValue / 100);
        if (appliedVoucher.maxDiscountAmount && discount > appliedVoucher.maxDiscountAmount) {
          discount = appliedVoucher.maxDiscountAmount;
        }
        totalDiscount = discount;
      } else if (appliedVoucher.discountType === "amount") {
        totalDiscount = appliedVoucher.discountValue;
      }
    }

    const createdOrders = [];
    let shopIndex = 0;
    let remainingDiscount = totalDiscount;

    for (const [shopId, shopItems] of itemsByShop) {
      const itemsTotal = shopItems.reduce(
        (sum, it) => sum + it.unit_price * it.quantity,
        0,
      );
      const shopDeliveryFee = shopIndex === 0 ? deliveryFee : 0;
      
      let orderDiscount = 0;
      if (remainingDiscount > 0) {
        orderDiscount = Math.min(remainingDiscount, itemsTotal + shopDeliveryFee);
        remainingDiscount -= orderDiscount;
      }

      const totalAmount = Math.max(0, itemsTotal + shopDeliveryFee - orderDiscount);

      const order = await orderModel.create({
        order_code: generateOrderCode(),
        user_id: user._id,
        shop_id: shopId,
        voucher_id: appliedVoucher ? appliedVoucher._id : null,
        address_id: address._id,
        payment_method,
        delivery_option,
        items_total: itemsTotal,
        discount_amount: orderDiscount,
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

    // Đánh dấu voucher đã sử dụng
    if (savedVoucherDoc) {
      savedVoucherDoc.status = "used";
      savedVoucherDoc.used_at = new Date();
      await savedVoucherDoc.save();

      if (appliedVoucher) {
        await voucherModel.findByIdAndUpdate(appliedVoucher._id, {
          $inc: { used_count: 1 }
        });
      }
    }

    dataRes.data = {
      orders: createdOrders,
      total_amount: createdOrders.reduce((sum, o) => sum + o.total_amount, 0),
    };

    if (payment_method === "vnpay" && createdOrders.length > 0) {
      const vnPayUtil = require("../utils/vnpay.util");
      const paymentUrl = await vnPayUtil.createPaymentUrl(req, createdOrders[0].order_code, dataRes.data.total_amount);
      dataRes.data.payment_url = paymentUrl;
    }

    return res.json(dataRes);
  } catch (err) {
    console.error("Create order error:", err.message);
    dataRes.msg = "Server error: " + err.message;
    return res.status(500).json(dataRes);
  }
};

