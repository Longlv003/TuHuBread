const mongoose = require("mongoose");
const { productModel } = require("../models/product.model");
const { productVariantModel } = require("../models/productVariant.model");
const { productOptionModel } = require("../models/productOption.model");
const { addressModel } = require("../models/address.model");
const { voucherModel } = require("../models/voucher.model");
const { voucherSaveModel } = require("../models/voucherSave.model");
const { cartModel } = require("../models/cart.model");
const { cartItemModel } = require("../models/cartItem.model");
const { shopModel } = require("../models/shop.model");
const orderRepository = require("../repositories/order.repository");
const orderStatusHistoryRepository = require("../repositories/orderStatusHistory.repository");
const socketService = require("./socket.service");
const notificationService = require("./notification.service");
const { calculateDeliveryFee, DELIVERY_MULTIPLIERS } = require("../utils/deliveryFee.util");
const { ORDER_STATUS_LABELS } = require("../utils/orderStatus.util");

const ORDER_FLOW = ["pending", "confirmed", "preparing", "delivering", "completed"];

function generateOrderCode() {
  const time = Date.now().toString(36).toUpperCase();
  const rand = Math.random().toString(36).slice(2, 6).toUpperCase();
  return `TH${time}${rand}`;
}

/**
 * Get the list of order_status values a shop owner may transition an order into.
 * @param {string} currentStatus
 */
function getAllowedNextStatuses(currentStatus) {
  if (currentStatus === "cancelled" || currentStatus === "completed") {
    return [];
  }

  const idx = ORDER_FLOW.indexOf(currentStatus);
  const next = idx >= 0 && idx < ORDER_FLOW.length - 1 ? [ORDER_FLOW[idx + 1]] : [];

  if (currentStatus === "pending" || currentStatus === "confirmed") {
    next.push("cancelled");
  }

  return next;
}

class OrderService {
  // --- Shop portal (order status management) ---

  getAllowedNextStatuses(currentStatus) {
    return getAllowedNextStatuses(currentStatus);
  }

  async getOrdersForShop(shopId, page = 1) {
    const parsedPage = Math.max(parseInt(page) || 1, 1);
    const limit = 10;
    const [orders, total] = await Promise.all([
      orderRepository.findByShopIdPaginated(shopId, { page: parsedPage, limit }),
      orderRepository.countByShopId(shopId),
    ]);
    return {
      orders,
      total,
      page: parsedPage,
      totalPages: Math.max(Math.ceil(total / limit), 1),
    };
  }

  async getOrderDetail(shopId, orderId) {
    const order = await orderRepository.findByIdScoped(orderId, shopId);
    if (!order) {
      throw new Error("Order not found");
    }
    const [items, history] = await Promise.all([
      orderRepository.findDetailsByOrderId(orderId),
      orderStatusHistoryRepository.findByOrderId(orderId)
    ]);
    return { order, items, history, nextStatuses: getAllowedNextStatuses(order.order_status) };
  }

  async updateOrderStatus(shopId, orderId, newStatus, changedByAccount, reason) {
    const order = await orderRepository.findByIdScoped(orderId, shopId);
    if (!order) {
      throw new Error("Order not found");
    }

    const allowed = getAllowedNextStatuses(order.order_status);
    if (!allowed.includes(newStatus)) {
      throw new Error(`Không thể chuyển từ '${order.order_status}' sang '${newStatus}'`);
    }

    if (newStatus === "cancelled" && !reason) {
      throw new Error("Vui lòng nhập lý do hủy đơn");
    }

    let paymentStatus;
    if (newStatus === "completed" && order.payment_method === "cash" && order.payment_status === "unpaid") {
      paymentStatus = "paid";
    }

    const previousStatus = order.order_status;
    const updated = await orderRepository.updateStatus(orderId, newStatus, paymentStatus);

    if (changedByAccount) {
      await orderStatusHistoryRepository.create({
        order_id: orderId,
        from_status: previousStatus,
        to_status: newStatus,
        changed_by: changedByAccount._id,
        changed_by_name: changedByAccount.full_name,
        note: newStatus === "cancelled" ? reason : null
      });
    }

    socketService.emitOrderUpdate(String(shopId), updated);

    const notifyBody = newStatus === "cancelled"
      ? `Đơn hàng của bạn đã bị hủy. Lý do: ${reason}`
      : `Đơn hàng của bạn đã chuyển sang trạng thái: ${ORDER_STATUS_LABELS[newStatus] || newStatus}`;

    notificationService.notifyUser(updated.user_id, {
      title: `Đơn hàng #${updated.order_code}`,
      body: notifyBody,
      type: "order",
      data: { order_id: String(updated._id), order_status: newStatus },
    });

    return updated;
  }

  // --- Customer-facing cart validation + order creation (used by cash + VNPay flows) ---

  async validateCartAndCalculate(userId, { addressId, deliveryOption, voucherCode, explicitItems }) {
    // 1. Lấy danh sách sản phẩm cần đặt: ưu tiên explicitItems nếu được truyền
    // (vd. "Mua ngay" từ trang chi tiết sản phẩm — gửi thẳng 1 sản phẩm chưa
    // nằm trong giỏ hàng thật), ngược lại lấy từ giỏ hàng thật của user (luồng
    // thanh toán bình thường từ tab Giỏ hàng).
    let cart = null;
    let cartItems;

    if (Array.isArray(explicitItems) && explicitItems.length > 0) {
      cartItems = explicitItems.map((it) => {
        if (
          !it.product_id || !mongoose.Types.ObjectId.isValid(it.product_id) ||
          !it.variant_id || !mongoose.Types.ObjectId.isValid(it.variant_id) ||
          !it.quantity || it.quantity <= 0
        ) {
          throw new Error("Dữ liệu sản phẩm không hợp lệ");
        }
        return {
          product_id: it.product_id,
          variant_id: it.variant_id,
          quantity: it.quantity,
          selected_options: it.selected_options || [],
          product_name: it.product_name || "",
          note: it.note || null,
        };
      });
    } else {
      cart = await cartModel.findOne({ user_id: userId, deleted_at: null, status: "active" });
      if (!cart) {
        throw new Error("Không tìm thấy giỏ hàng hoạt động");
      }

      cartItems = await cartItemModel.find({ cart_id: cart._id, deleted_at: null });
      if (!cartItems || cartItems.length === 0) {
        throw new Error("Giỏ hàng của bạn đang trống");
      }
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
    if (!DELIVERY_MULTIPLIERS.hasOwnProperty(deliveryOption)) {
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

    // Tính phí ship theo khoảng cách thực tế từ chi nhánh tới địa chỉ giao
    // hàng (đồng nhất với luồng thanh toán tiền mặt) — giỏ hàng chỉ chứa sản
    // phẩm của 1 chi nhánh tại 1 thời điểm nên lấy toạ độ từ item đầu tiên là đủ.
    const shop = await shopModel.findOne({ _id: validatedItems[0].shop_id, deleted_at: null });
    const deliveryFee = calculateDeliveryFee(
      shop && shop.location ? shop.location.coordinates : undefined,
      address.location ? address.location.coordinates : undefined,
      deliveryOption,
    );

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
      socketService.emitNewOrder(String(shopId), order);
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
