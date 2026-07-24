const mongoose = require("mongoose");
const { orderModel } = require("../models/order.model");
const { orderDetailModel } = require("../models/orderDetail.model");
const { productModel } = require("../models/product.model");
const { productVariantModel } = require("../models/productVariant.model");
const { productOptionModel } = require("../models/productOption.model");
const { addressModel } = require("../models/address.model");
const { voucherModel } = require("../models/voucher.model");
const { voucherSaveModel } = require("../models/voucherSave.model");
const { cartModel } = require("../models/cart.model");
const { cartItemModel } = require("../models/cartItem.model");
const orderRepository = require("../repositories/order.repository");

const DELIVERY_FEES = {
  priority: 25000,
  standard: 15000,
  saving: 0,
};

function generateOrderCode() {
  const time = Date.now().toString(36).toUpperCase();
  const rand = Math.random().toString(36).slice(2, 6).toUpperCase();
  return `TH${time}${rand}`;
}

class OrderService {
  async validateCartAndCalculate(userId, { addressId, deliveryOption, voucherCode }) {
    // 1. Lấy giỏ hàng của user
    const cart = await cartModel.findOne({ user_id: userId, deleted_at: null, status: "active" });
    if (!cart) {
      throw new Error("Không tìm thấy giỏ hàng hoạt động");
    }

    const cartItems = await cartItemModel.find({ cart_id: cart._id, deleted_at: null });
    if (!cartItems || cartItems.length === 0) {
      throw new Error("Giỏ hàng của bạn đang trống");
    }

    // 2. Validate địa chỉ
    if (!addressId || !mongoose.Types.ObjectId.isValid(addressId)) {
      throw new Error("Thiếu hoặc sai địa chỉ giao hàng");
    }
    const address = await addressModel.findOne({ _id: addressId, user_id: userId, deleted_at: null });
    if (!address) {
      throw new Error("Địa chỉ giao hàng không hợp lệ hoặc đã bị xóa");
    }

    // 3. Validate delivery option
    if (!DELIVERY_FEES.hasOwnProperty(deliveryOption)) {
      throw new Error("Tùy chọn giao hàng không hợp lệ");
    }

    // 4. Duyệt các item để validate product, variant, option và tính lại giá gốc từ DB
    const validatedItems = [];
    for (const item of cartItems) {
      const product = await productModel.findOne({ _id: item.product_id, deleted_at: null, status: "active" });
      if (!product) {
        throw new Error(`Sản phẩm "${item.product_name}" không tồn tại hoặc đã ngừng bán`);
      }

      const variant = await productVariantModel.findOne({
        _id: item.variant_id,
        product_id: item.product_id,
        deleted_at: null,
        status: "active",
      });
      if (!variant) {
        throw new Error(`Phiên bản sản phẩm "${item.product_name}" không khả dụng`);
      }

      // Giá gốc (giá KM nếu có)
      let basePrice = variant.price;
      if (variant.sale_price !== null && variant.sale_price !== undefined) {
        basePrice = variant.sale_price;
      }

      // Validate Options và tính tiền option
      let optionTotalPrice = 0;
      const verifiedOptions = [];
      if (Array.isArray(item.selected_options) && item.selected_options.length > 0) {
        for (const opt of item.selected_options) {
          const optId = opt.option_id || opt._id;
          const optionDoc = await productOptionModel.findOne({
            _id: optId,
            product_id: item.product_id,
            deleted_at: null,
            status: "active",
          });
          if (!optionDoc) {
            throw new Error(`Tùy chọn "${opt.option_name}" của sản phẩm không khả dụng`);
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
      validatedItems.push({
        product_id: product._id,
        variant_id: variant._id,
        shop_id: product.shop_id,
        quantity: item.quantity,
        product_name: product.product_name,
        variant_name: variant.variant_name,
        product_image: variant.image || null,
        base_price: basePrice,
        selected_options: verifiedOptions,
        option_total_price: optionTotalPrice,
        unit_price: unitPrice,
        subtotal: unitPrice * item.quantity,
        note: item.note || null,
      });
    }

    // 5. Tính items_total
    const itemsTotal = validatedItems.reduce((sum, it) => sum + it.subtotal, 0);

    // 6. Xử lý Voucher
    let appliedVoucher = null;
    let savedVoucherDoc = null;
    let discountAmount = 0;

    if (voucherCode) {
      savedVoucherDoc = await voucherSaveModel.findOne({
        user_id: userId,
        voucher_code: voucherCode,
        status: "saved",
        expires_at: { $gt: new Date() }
      }).populate("voucher_id");

      if (!savedVoucherDoc || !savedVoucherDoc.voucher_id) {
        throw new Error("Voucher không hợp lệ hoặc đã hết hạn");
      }

      appliedVoucher = savedVoucherDoc.voucher_id;
      if (itemsTotal < appliedVoucher.minOrderAmount) {
        throw new Error(`Đơn hàng tối thiểu phải từ ${appliedVoucher.minOrderAmount}đ để sử dụng voucher này`);
      }

      if (appliedVoucher.usageLimit && appliedVoucher.used_count >= appliedVoucher.usageLimit) {
        throw new Error("Voucher đã hết lượt sử dụng");
      }
    }

    const deliveryFee = DELIVERY_FEES[deliveryOption];

    // Tính toán discount tổng
    if (appliedVoucher) {
      if (appliedVoucher.discountType === "free_shipping") {
        discountAmount = deliveryFee;
      } else if (appliedVoucher.discountType === "percent") {
        let discount = itemsTotal * (appliedVoucher.discountValue / 100);
        if (appliedVoucher.maxDiscountAmount && discount > appliedVoucher.maxDiscountAmount) {
          discount = appliedVoucher.maxDiscountAmount;
        }
        discountAmount = discount;
      } else if (appliedVoucher.discountType === "amount") {
        discountAmount = appliedVoucher.discountValue;
      }
    }

    const totalAmount = Math.max(0, itemsTotal + deliveryFee - discountAmount);

    return {
      validatedItems,
      itemsTotal,
      deliveryFee,
      discountAmount,
      totalAmount,
      appliedVoucher,
      savedVoucherDoc,
      address,
      cart,
    };
  }

  async createOrderFromCart(user, { addressId, deliveryOption, paymentMethod, voucherCode, note }) {
    // 1. Validate & tính lại toàn bộ giá trên server
    const calc = await this.validateCartAndCalculate(user._id, { addressId, deliveryOption, voucherCode });

    // 2. Nhóm items theo shop để chia đơn hàng nếu cần (mỗi shop 1 đơn)
    const itemsByShop = new Map();
    for (const item of calc.validatedItems) {
      const key = String(item.shop_id);
      if (!itemsByShop.has(key)) itemsByShop.set(key, []);
      itemsByShop.get(key).push(item);
    }

    const createdOrders = [];
    let remainingDiscount = calc.discountAmount;
    let shopIndex = 0;

    for (const [shopId, shopItems] of itemsByShop) {
      const shopItemsTotal = shopItems.reduce((sum, it) => sum + it.subtotal, 0);
      const shopDeliveryFee = shopIndex === 0 ? calc.deliveryFee : 0;

      let orderDiscount = 0;
      if (remainingDiscount > 0) {
        orderDiscount = Math.min(remainingDiscount, shopItemsTotal + shopDeliveryFee);
        remainingDiscount -= orderDiscount;
      }

      const shopTotalAmount = Math.max(0, shopItemsTotal + shopDeliveryFee - orderDiscount);
      const orderCode = generateOrderCode();

      // Sử dụng repository để tạo order
      const order = await orderRepository.createOrder({
        order_code: orderCode,
        user_id: user._id,
        shop_id: shopId,
        voucher_id: calc.appliedVoucher ? calc.appliedVoucher._id : null,
        address_id: calc.address._id,
        payment_method: paymentMethod,
        delivery_option: deliveryOption,
        payment_status: "unpaid",
        order_status: "pending",
        items_total: shopItemsTotal,
        discount_amount: orderDiscount,
        delivery_fee: shopDeliveryFee,
        total_amount: shopTotalAmount,
        note: note || null,
      });

      // Tạo order details
      for (const item of shopItems) {
        await orderRepository.createOrderDetail({
          order_id: order._id,
          product_id: item.product_id,
          variant_id: item.variant_id,
          quantity: item.quantity,
          product_name: item.product_name,
          variant_name: item.variant_name,
          product_image: item.product_image,
          base_price: item.base_price,
          selected_options: item.selected_options,
          option_total_price: item.option_total_price,
          unit_price: item.unit_price,
          subtotal: item.subtotal,
          note: item.note,
        });
      }

      createdOrders.push(order);
      shopIndex += 1;
    }

    // 3. Đánh dấu voucher đã dùng (nếu có)
    if (calc.savedVoucherDoc) {
      calc.savedVoucherDoc.status = "used";
      calc.savedVoucherDoc.used_at = new Date();
      await calc.savedVoucherDoc.save();

      if (calc.appliedVoucher) {
        await voucherModel.findByIdAndUpdate(calc.appliedVoucher._id, {
          $inc: { used_count: 1 }
        });
      }
    }

    // 4. Xóa hẳn các cart items trong giỏ hàng (vì đã chuyển thành order)
    await cartItemModel.deleteMany({ cart_id: calc.cart._id });

    // Recalculate cart total (set to 0)
    calc.cart.cart_total = 0;
    await calc.cart.save();

    return {
      orders: createdOrders,
      totalAmount: calc.totalAmount,
    };
  }
}

module.exports = new OrderService();
