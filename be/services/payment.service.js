"use strict";

const {
  VNPay,
  ignoreLogger,
  ProductCode,
  VnpLocale,
  dateFormat,
} = require("vnpay");
require("dotenv").config();

const orderRepository = require("../repositories/order.repository");
const paymentSessionRepository = require("../repositories/payment_session.repository");
const orderService = require("./order.service");
const { cartModel } = require("../models/cart.model");
const { cartItemModel } = require("../models/cartItem.model");
const { voucherModel } = require("../models/voucher.model");

// ─── Helpers ─────────────────────────────────────────────────────────────────

/**
 * Tạo instance VNPay từ biến môi trường.
 */
function buildVnpayInstance() {
  const { VNP_TMNCODE, VNP_HASH_SECRET } = process.env;
  if (!VNP_TMNCODE || !VNP_HASH_SECRET) {
    throw new Error("Thiếu cấu hình VNPAY (VNP_TMNCODE hoặc VNP_HASH_SECRET)");
  }
  return new VNPay({
    tmnCode: VNP_TMNCODE,
    secureSecret: VNP_HASH_SECRET,
    vnpayHost: process.env.VNP_HOST || "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html",
    testMode: true,
    hashAlgorithm: "SHA512",
    loggerFn: ignoreLogger,
  });
}

/**
 * Lấy IP thật của client, ưu tiên header X-Forwarded-For.
 * @param {import('express').Request} req
 * @returns {string}
 */
function resolveClientIp(req) {
  const forwarded = req.headers["x-forwarded-for"];
  const ip =
    (typeof forwarded === "string" && forwarded.split(",")[0].trim()) ||
    req.socket?.remoteAddress ||
    req.connection?.remoteAddress ||
    "127.0.0.1";
  return ip.replace("::ffff:", "");
}

/**
 * Tạo mã đơn hàng ngẫu nhiên dạng TH + timestamp36 + 4 ký tự ngẫu nhiên.
 * @returns {string}
 */
function generateOrderCode() {
  const time = Date.now().toString(36).toUpperCase();
  const rand = Math.random().toString(36).slice(2, 6).toUpperCase();
  return `TH${time}${rand}`;
}

// ─── Payment Service ──────────────────────────────────────────────────────────

class PaymentService {
  /**
   * Tạo URL thanh toán VNPAY.
   *
   * Luồng:
   *  1. Gọi orderService.validateCartAndCalculate() để validate & tính giá server-side.
   *  2. Snapshot toàn bộ dữ liệu đã validate vào paymentSessionModel (status=PENDING).
   *  3. Dùng session._id làm vnp_TxnRef (1 ID duy nhất, không có dấu phẩy).
   *  4. Đánh dấu voucher "đang dùng" (nếu có), nhưng CHƯA tiêu dùng thật sự.
   *  5. Build & trả về paymentUrl.
   *
   * @param {import('express').Request} req
   * @param {Object} user  — document userModel đã resolve từ firebase_uid
   * @param {Object} params
   * @param {string} params.addressId
   * @param {string} params.deliveryOption
   * @param {string|null} params.voucherCode
   * @param {string|null} params.note
   * @param {string} [params.locale="VN"]
   * @returns {Promise<{ paymentUrl: string, totalAmount: number }>}
   */
  async createPaymentUrl(req, user, { addressId, deliveryOption, voucherCode, note, locale = "VN" }) {
    // 1. Validate giỏ hàng & tính giá server-side
    const calc = await orderService.validateCartAndCalculate(user._id, {
      addressId,
      deliveryOption,
      voucherCode,
    });

    // 2. Tạo payment session (snapshot)
    const session = await paymentSessionRepository.create({
      user_id: user._id,
      address_id: calc.address._id,
      items: calc.validatedItems.map((it) => ({
        product_id: it.product_id,
        variant_id: it.variant_id,
        shop_id: it.shop_id,
        quantity: it.quantity,
        product_name: it.product_name,
        variant_name: it.variant_name,
        product_image: it.product_image || null,
        base_price: it.base_price,
        selected_options: it.selected_options,
        option_total_price: it.option_total_price,
        unit_price: it.unit_price,
        subtotal: it.subtotal,
        note: it.note || null,
      })),
      items_total: calc.itemsTotal,
      delivery_fee: calc.deliveryFee,
      discount_amount: calc.discountAmount,
      total_amount: calc.totalAmount,
      delivery_option: deliveryOption,
      voucher_id: calc.appliedVoucher ? calc.appliedVoucher._id : null,
      order_note: note || null,
      status: "PENDING",
    });

    const txnRef = session._id.toString();

    // 3. Build VNPAY URL
    const vnpay = buildVnpayInstance();
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);

    const orderInfo = `Thanh toan don hang ${txnRef}`;
    const ipAddr = resolveClientIp(req);

    const paymentUrl = await vnpay.buildPaymentUrl({
      vnp_Amount: Math.round(calc.totalAmount),
      vnp_IpAddr: ipAddr,
      vnp_TxnRef: txnRef,
      vnp_OrderInfo: orderInfo,
      vnp_OrderType: ProductCode.Other,
      vnp_ReturnUrl: process.env.VNP_RETURN_URL,
      vnp_Locale: locale === "EN" ? VnpLocale.EN : VnpLocale.VN,
      vnp_CreateDate: dateFormat(new Date()),
      vnp_ExpireDate: dateFormat(tomorrow),
    });

    return { paymentUrl, totalAmount: calc.totalAmount };
  }


  /**
   * Xác minh chữ ký VNPAY Return URL.
   * @param {Object} vnpParams — req.query từ VNPAY
   * @returns {boolean}
   */
  verifyReturnUrl(vnpParams) {
    const vnpay = buildVnpayInstance();
    return vnpay.verifyReturnUrl(vnpParams);
  }

  /**
   * Xác minh chữ ký VNPAY IPN.
   * @param {Object} vnpParams — req.query từ VNPAY
   * @returns {boolean}
   */
  verifyIpnCall(vnpParams) {
    const vnpay = buildVnpayInstance();
    return vnpay.verifyIpnCall(vnpParams);
  }

  /**
   * Xác nhận kết quả thanh toán từ VNPAY và thực hiện các tác vụ sau thanh toán:
   *  - Nếu VNPAY trả về 00 (thành công):
   *    a. Tách items trong session theo shop_id → tạo Order + OrderDetail cho mỗi shop.
   *    b. Hard-delete cart_items.
   *    c. Đánh dấu voucher đã dùng.
   *    d. Cập nhật session → PAID.
   *  - Nếu thất bại: cập nhật session → FAILED.
   *
   * @param {Object} params
   * @param {string} params.txnRef         — vnp_TxnRef (session._id)
   * @param {string} params.amount         — vnp_Amount (VND * 100)
   * @param {string} params.responseCode   — vnp_ResponseCode
   * @param {string} params.transactionStatus — vnp_TransactionStatus
   * @param {string} params.transactionNo  — vnp_TransactionNo
   * @param {string} params.bankCode       — vnp_BankCode
   * @returns {Promise<{ RspCode: string, Message: string, orderCodes?: string[] }>}
   */
  async confirmPayment({ txnRef, amount, responseCode, transactionStatus, transactionNo, bankCode }) {
    // 1. Tìm session
    const session = await paymentSessionRepository.findById(txnRef);
    if (!session) {
      return { RspCode: "01", Message: "Order not found" };
    }

    // 2. Kiểm tra idempotency — đã xử lý rồi thì không làm lại
    if (session.status === "PAID") {
      return { RspCode: "02", Message: "Order already confirmed" };
    }
    if (session.status === "FAILED") {
      return { RspCode: "02", Message: "Order already failed" };
    }

    // 3. Kiểm tra số tiền
    const normalizedAmount = Number(amount) / 100;
    if (Math.round(session.total_amount) !== Math.round(normalizedAmount)) {
      return { RspCode: "04", Message: "Invalid amount" };
    }

    // 4. Kiểm tra trạng thái giao dịch
    const isSuccess = responseCode === "00" && (transactionStatus || responseCode) === "00";

    if (isSuccess) {
      return await this._handleSuccessPayment(session, { transactionNo, bankCode, responseCode });
    } else {
      return await this._handleFailedPayment(session, { transactionNo, responseCode });
    }
  }

  /**
   * Xử lý thanh toán thành công — tạo orders thực tế từ session.
   * @private
   */
  async _handleSuccessPayment(session, { transactionNo, bankCode, responseCode }) {
    // 1. Gom nhóm items theo shop_id
    const itemsByShop = new Map();
    for (const item of session.items) {
      const key = item.shop_id.toString();
      if (!itemsByShop.has(key)) itemsByShop.set(key, []);
      itemsByShop.get(key).push(item);
    }

    const createdOrders = [];
    let remainingDiscount = session.discount_amount;
    let shopIndex = 0;

    // 2. Tạo Order + OrderDetail riêng cho mỗi shop
    for (const [shopId, shopItems] of itemsByShop) {
      const shopItemsTotal = shopItems.reduce((sum, it) => sum + it.subtotal, 0);
      // Phí ship gán hết cho shop đầu tiên (đơn giản hoá)
      const shopDeliveryFee = shopIndex === 0 ? session.delivery_fee : 0;

      let orderDiscount = 0;
      if (remainingDiscount > 0) {
        orderDiscount = Math.min(remainingDiscount, shopItemsTotal + shopDeliveryFee);
        remainingDiscount -= orderDiscount;
      }

      const shopTotal = Math.max(0, shopItemsTotal + shopDeliveryFee - orderDiscount);

      const order = await orderRepository.createOrder({
        order_code: generateOrderCode(),
        user_id: session.user_id,
        shop_id: shopId,
        voucher_id: session.voucher_id || null,
        address_id: session.address_id,
        payment_method: "vnpay",
        delivery_option: session.delivery_option,
        payment_status: "paid",
        order_status: "confirmed",
        items_total: shopItemsTotal,
        discount_amount: orderDiscount,
        delivery_fee: shopDeliveryFee,
        total_amount: shopTotal,
        note: session.order_note || null,
      });

      for (const item of shopItems) {
        await orderRepository.createOrderDetail({
          order_id: order._id,
          product_id: item.product_id,
          variant_id: item.variant_id,
          quantity: item.quantity,
          product_name: item.product_name,
          variant_name: item.variant_name,
          product_image: item.product_image || null,
          base_price: item.base_price,
          selected_options: item.selected_options || [],
          option_total_price: item.option_total_price || 0,
          unit_price: item.unit_price,
          subtotal: item.subtotal,
          note: item.note || null,
        });
      }

      createdOrders.push(order);
      shopIndex++;
    }

    // 3. Hard-delete cart_items
    const activeCart = await cartModel.findOne({
      user_id: session.user_id,
      status: "active",
      deleted_at: null,
    });
    if (activeCart) {
      await cartItemModel.deleteMany({ cart_id: activeCart._id });
      activeCart.cart_total = 0;
      await activeCart.save();
    }

    // 4. Đánh dấu voucher đã dùng (nếu có)
    if (session.voucher_id) {
      const { voucherSaveModel } = require("../models/voucherSave.model");
      await voucherSaveModel.findOneAndUpdate(
        { user_id: session.user_id, voucher_id: session.voucher_id, status: "saved" },
        { status: "used", used_at: new Date() }
      );
      await voucherModel.findByIdAndUpdate(session.voucher_id, {
        $inc: { used_count: 1 },
      });
    }

    // 5. Cập nhật session → PAID
    session.status = "PAID";
    session.vnp_transaction_no = transactionNo || null;
    session.vnp_bank_code = bankCode || null;
    session.vnp_response_code = responseCode || null;
    session.paid_at = new Date();
    session.order_ids = createdOrders.map((o) => o._id);
    await session.save();

    return {
      RspCode: "00",
      Message: "Confirm Success",
      orderCodes: createdOrders.map((o) => o.order_code),
    };
  }

  /**
   * Xử lý thanh toán thất bại.
   * @private
   */
  async _handleFailedPayment(session, { transactionNo, responseCode }) {
    session.status = "FAILED";
    session.vnp_transaction_no = transactionNo || null;
    session.vnp_response_code = responseCode || null;
    await session.save();

    return { RspCode: "00", Message: "Payment failed recorded" };
  }
}

module.exports = new PaymentService();
