const mongoose = require("mongoose");
const { userModel } = require("../models/user.model");
const { addressModel } = require("../models/address.model");
const { shopModel } = require("../models/shop.model");
const { orderModel } = require("../models/order.model");
const { orderDetailModel } = require("../models/orderDetail.model");
const { productModel } = require("../models/product.model");
const { productVariantModel } = require("../models/productVariant.model");
const { productOptionModel } = require("../models/productOption.model");
const { cartModel } = require("../models/cart.model");
const { cartItemModel } = require("../models/cartItem.model");
const { voucherModel } = require("../models/voucher.model");
const { voucherSaveModel } = require("../models/voucherSave.model");
const socketService = require("../services/socket.service");
const notificationService = require("../services/notification.service");
const { calculateDeliveryFee, DELIVERY_MULTIPLIERS } = require("../utils/deliveryFee.util");
const { buildCartItemConfigKey } = require("../utils/cartItemKey.util");
const orderStatusHistoryRepository = require("../repositories/orderStatusHistory.repository");

const PAYMENT_METHODS = ["cash", "vnpay"];

async function findCurrentUser(req) {
  return userModel.findOne({ firebase_uid: req.user.uid });
}

function generateOrderCode() {
  const time = Date.now().toString(36).toUpperCase();
  const rand = Math.random().toString(36).slice(2, 6).toUpperCase();
  return `TH${time}${rand}`;
}

// GET /api/orders
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

// GET /api/orders/:id
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

// POST /api/orders/:id/cancel
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

    const previousStatus = order.order_status;
    order.order_status = "cancelled";
    await order.save();

    // Lưu lịch sử thay đổi trạng thái (khách hàng tự huỷ) + báo realtime cho shop
    await orderStatusHistoryRepository.create({
      order_id: order._id,
      from_status: previousStatus,
      to_status: "cancelled",
      changed_by: user._id,
      changed_by_name: user.full_name,
      note: "Khách hàng tự hủy đơn",
    });
    socketService.emitOrderUpdate(String(order.shop_id), order);

    dataRes.msg = "Hủy đơn hàng thành công";
    dataRes.data = order;

  } catch (err) {
    console.error("cancelOrder error:", err.message);
    dataRes.msg = "Server error: " + err.message;
    return res.status(500).json(dataRes);
  }
  return res.json(dataRes);
};

// GET /api/delivery-fee/preview?shop_id=&address_id=
// Xem trước phí ship theo khoảng cách thật cho cả 3 tuỳ chọn giao hàng —
// dùng ở màn Thanh toán để cập nhật giá ngay khi đổi địa chỉ, trước khi đặt
// hàng thật (không tạo order/thay đổi dữ liệu gì).
exports.previewDeliveryFee = async (req, res) => {
  let dataRes = { msg: "OK", data: null };
  try {
    const { uid } = req.user;
    const user = await userModel.findOne({ firebase_uid: uid });
    if (!user) {
      dataRes.msg = "User not found";
      return res.status(404).json(dataRes);
    }

    const { shop_id, address_id } = req.query;
    if (!shop_id || !mongoose.Types.ObjectId.isValid(shop_id) ||
        !address_id || !mongoose.Types.ObjectId.isValid(address_id)) {
      dataRes.msg = "Thiếu hoặc sai shop_id/address_id";
      return res.status(400).json(dataRes);
    }

    const [shop, address] = await Promise.all([
      shopModel.findOne({ _id: shop_id, deleted_at: null }),
      addressModel.findOne({ _id: address_id, user_id: user._id, deleted_at: null }),
    ]);
    if (!shop) {
      dataRes.msg = "Không tìm thấy cửa hàng";
      return res.status(404).json(dataRes);
    }
    if (!address) {
      dataRes.msg = "Không tìm thấy địa chỉ";
      return res.status(404).json(dataRes);
    }

    const shopCoords = shop.location ? shop.location.coordinates : undefined;
    const addressCoords = address.location ? address.location.coordinates : undefined;

    dataRes.status = "success";
    dataRes.data = {
      priority: calculateDeliveryFee(shopCoords, addressCoords, "priority"),
      standard: calculateDeliveryFee(shopCoords, addressCoords, "standard"),
      saving: calculateDeliveryFee(shopCoords, addressCoords, "saving"),
    };
    return res.json(dataRes);
  } catch (err) {
    console.error("previewDeliveryFee error:", err.message);
    dataRes.msg = "Server error: " + err.message;
    return res.status(500).json(dataRes);
  }
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

    if (!DELIVERY_MULTIPLIERS.hasOwnProperty(delivery_option)) {
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

    // Validate từng item + tính lại giá server-side từ product/variant/option
    // (không tin tưởng unit_price do client gửi lên)
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

    // Verify all items belong to the same shop
    const shopId = items[0].shop_id;
    for (const item of items) {
      if (String(item.shop_id) !== String(shopId)) {
        dataRes.msg = "Tất cả sản phẩm trong đơn hàng phải thuộc cùng một cửa hàng";
        return res.status(400).json(dataRes);
      }
    }

    const shop = await shopModel.findOne({ _id: shopId, deleted_at: null });
    if (!shop) {
      dataRes.msg = "Không tìm thấy cửa hàng cho một số sản phẩm trong giỏ hàng";
      return res.status(404).json(dataRes);
    }

    const itemsTotal = items.reduce(
      (sum, it) => sum + it.unit_price * it.quantity,
      0,
    );
    const deliveryFee = calculateDeliveryFee(
      shop.location ? shop.location.coordinates : undefined,
      address.location ? address.location.coordinates : undefined,
      delivery_option,
    );

    // Tính toán lượng giảm giá tổng của voucher
    let totalDiscount = 0;
    if (appliedVoucher) {
      if (appliedVoucher.discountType === "free_shipping") {
        totalDiscount = deliveryFee;
      } else if (appliedVoucher.discountType === "percent") {
        let discount = itemsTotal * (appliedVoucher.discountValue / 100);
        if (appliedVoucher.maxDiscountAmount && discount > appliedVoucher.maxDiscountAmount) {
          discount = appliedVoucher.maxDiscountAmount;
        }
        totalDiscount = discount;
      } else if (appliedVoucher.discountType === "amount") {
        totalDiscount = appliedVoucher.discountValue;
      }
    }

    const orderDiscount = Math.min(totalDiscount, itemsTotal + deliveryFee);
    const totalAmount = Math.max(0, itemsTotal + deliveryFee - orderDiscount);

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
      delivery_fee: deliveryFee,
      total_amount: totalAmount,
      note: note || null,
    });

    await orderDetailModel.insertMany(
      items.map((it) => ({
        order_id: order._id,
        product_id: it.product_id,
        variant_id: it.variant_id,
        quantity: it.quantity,
        product_name: it.product_name,
        variant_name: it.variant_name,
        product_image: it.product_image || null,
        base_price: it.base_price,
        selected_options: it.selected_options || [],
        option_total_price: it.option_total_price || 0,
        unit_price: it.unit_price,
        subtotal: it.unit_price * it.quantity,
      })),
    );

    socketService.emitNewOrder(shopId, order);
    notificationService.notifyUser(user._id, {
      title: "Đặt hàng thành công",
      body: `Đơn hàng #${order.order_code} của bạn đã được tiếp nhận.`,
      type: "order",
      data: { order_id: String(order._id), order_status: order.order_status },
    });

    const createdOrders = [
      {
        order_id: order._id,
        order_code: order.order_code,
        shop_id: shopId,
        items_total: itemsTotal,
        delivery_fee: deliveryFee,
        total_amount: totalAmount,
      }
    ];

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

    // Xoá khỏi giỏ hàng đúng những sản phẩm vừa đặt (không xoá toàn bộ giỏ hàng,
    // vì "Mua ngay" gửi thẳng 1 sản phẩm không nằm trong giỏ — xoá hết sẽ làm mất
    // các sản phẩm khác khách đã thêm vào giỏ từ trước).
    try {
      const cart = await cartModel.findOne({ user_id: user._id, status: "active" });
      if (cart) {
        const orderedKeys = new Set(
          items.map((it) =>
            buildCartItemConfigKey(
              String(it.product_id),
              String(it.variant_id),
              (it.selected_options || []).map((o) => o.option_id),
            ),
          ),
        );

        const cartItems = await cartItemModel.find({ cart_id: cart._id, deleted_at: null });
        const idsToDelete = cartItems
          .filter((ci) =>
            orderedKeys.has(
              buildCartItemConfigKey(
                String(ci.product_id),
                String(ci.variant_id),
                (ci.selected_options || []).map((o) => o.option_id),
              ),
            ),
          )
          .map((ci) => ci._id);

        if (idsToDelete.length > 0) {
          await cartItemModel.deleteMany({ _id: { $in: idsToDelete } });
        }

        const remainingItems = await cartItemModel.find({ cart_id: cart._id, deleted_at: null });
        cart.cart_total = remainingItems.reduce((sum, it) => sum + it.subtotal, 0);
        await cart.save();
      }
    } catch (cartErr) {
      console.error("Clear cart error post order:", cartErr.message);
    }

    return res.json(dataRes);
  } catch (err) {
    console.error("Create order error:", err.message);
    dataRes.msg = "Server error: " + err.message;
    return res.status(500).json(dataRes);
  }
};
