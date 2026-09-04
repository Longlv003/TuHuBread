"use strict";

const { SePayPgClient } = require("sepay-pg-node");
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
const { buildCartItemConfigKey } = require("../utils/cartItemKey.util");
const socketService = require("./socket.service");
const notificationService = require("./notification.service");
const { NOTIFICATION_TYPES } = require("../constants/notification.constants");

// ─── Helpers ─────────────────────────────────────────────────────────────────

/**
 * Tạo instance SePay Payment Gateway từ biến môi trường.
 */
function buildSepayClient() {
  const { SEPAY_MERCHANT_ID, SEPAY_SECRET_KEY, SEPAY_ENV } = process.env;
  if (!SEPAY_MERCHANT_ID || !SEPAY_SECRET_KEY) {
    throw new Error("Thiếu cấu hình SePay (SEPAY_MERCHANT_ID hoặc SEPAY_SECRET_KEY)");
  }
  return new SePayPgClient({
    env: SEPAY_ENV === "production" ? "production" : "sandbox",
    merchant_id: SEPAY_MERCHANT_ID,
    secret_key: SEPAY_SECRET_KEY,
  });
}

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
   * Validate giỏ hàng & tạo payment session (snapshot) dùng chung cho cả
   * SePay và VNPay — mỗi cổng chỉ khác nhau ở bước build URL/biểu mẫu thanh
   * toán phía sau, phần validate + snapshot giỏ hàng là như nhau.
   * @private
   */
  async _createSession(user, { addressId, deliveryOption, voucherCode, note, items, gateway }) {
    const calc = await orderService.validateCartAndCalculate(user._id, {
      addressId,
      deliveryOption,
      voucherCode,
      explicitItems: items,
    });

    const session = await paymentSessionRepository.create({
      user_id: user._id,
      address_id: calc.address._id,
      gateway,
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

    return { session, calc };
  }

  /**
   * Tạo biểu mẫu thanh toán SePay từ giỏ hàng hiện tại.
   *
   * Luồng:
   *  1. Gọi orderService.validateCartAndCalculate() để validate & tính giá server-side.
   *  2. Snapshot toàn bộ dữ liệu đã validate vào paymentSessionModel (status=PENDING).
   *  3. Dùng session._id làm order_invoice_number (1 ID duy nhất).
   *  4. Đánh dấu voucher "đang dùng" (nếu có), nhưng CHƯA tiêu dùng thật sự.
   *  5. Build & trả về checkoutUrl + checkoutFields (biểu mẫu POST đã ký).
   *
   * @param {import('express').Request} req
   * @param {Object} user  — document userModel đã resolve từ firebase_uid
   * @param {Object} params
   * @param {string} params.addressId
   * @param {string} params.deliveryOption
   * @param {string|null} params.voucherCode
   * @param {string|null} params.note
   * @param {Array|undefined} params.items — nếu có (vd. "Mua ngay"), thanh
   *   toán đúng các sản phẩm này thay vì đọc toàn bộ giỏ hàng thật.
   * @returns {Promise<{ checkoutUrl: string, checkoutFields: Object, txnRef: string, totalAmount: number }>}
   */
  async createPaymentUrl(req, user, { addressId, deliveryOption, voucherCode, note, items }) {
    const { session, calc } = await this._createSession(user, {
      addressId,
      deliveryOption,
      voucherCode,
      note,
      items,
      gateway: "sepay",
    });

    // txnRef dùng làm order_invoice_number cho SePay — phải DUY NHẤT tuyệt đối
    // (SePay từ chối nếu trùng mã đã dùng trước đó), session._id (ObjectId)
    // đảm bảo điều này tương tự cách VNPay dùng txnRef.
    const txnRef = session._id.toString();

    // Build biểu mẫu thanh toán SePay (POST form) — khác VNPay ở chỗ SePay
    // KHÔNG trả về 1 URL để redirect GET, mà trả checkoutUrl + các field cần
    // POST kèm chữ ký HMAC-SHA256 do chính SDK tự tính (không tự viết logic ký
    // tay, để đảm bảo khớp thuật toán mà server SePay kiểm tra).
    // Gắn kèm txnRef vào URL callback — SePay redirect về ĐÚNG URL này (kèm
    // nguyên query string) nên đây là cách duy nhất để nhận diện đúng giao
    // dịch nào khi khách quay lại (SDK không tự đính order_invoice_number vào
    // URL trả về).
    const returnUrl = `${process.env.SEPAY_RETURN_URL}?txnRef=${txnRef}`;

    const client = buildSepayClient();
    const checkoutFields = client.checkout.initOneTimePaymentFields({
      operation: "PURCHASE",
      payment_method: "BANK_TRANSFER",
      order_invoice_number: txnRef,
      order_amount: Math.round(calc.totalAmount),
      currency: "VND",
      order_description: `Thanh toan don hang ${txnRef}`,
      success_url: returnUrl,
      error_url: returnUrl,
      cancel_url: returnUrl,
    });

    return {
      checkoutUrl: client.checkout.initCheckoutUrl(),
      checkoutFields,
      txnRef,
      totalAmount: calc.totalAmount,
    };
  }

  /**
   * Tạo URL thanh toán VNPAY từ giỏ hàng hiện tại — cùng luồng validate +
   * snapshot session như SePay ([_createSession]), chỉ khác bước build URL:
   * VNPay chỉ cần 1 URL để redirect GET (không cần POST biểu mẫu như SePay).
   *
   * @param {import('express').Request} req
   * @param {Object} user
   * @param {Object} params — giống [createPaymentUrl], thêm `locale`
   * @returns {Promise<{ paymentUrl: string, txnRef: string, totalAmount: number }>}
   */
  async createVnpayPaymentUrl(req, user, { addressId, deliveryOption, voucherCode, note, locale = "VN", items }) {
    const { session, calc } = await this._createSession(user, {
      addressId,
      deliveryOption,
      voucherCode,
      note,
      items,
      gateway: "vnpay",
    });

    const txnRef = session._id.toString();

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

    return { paymentUrl, txnRef, totalAmount: calc.totalAmount };
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
   * Tra cứu trạng thái giao dịch THẬT từ SePay — KHÔNG tin theo tham số trong
   * URL callback (success_url/error_url), vì SDK không cung cấp cách verify
   * chữ ký cho các callback này. Đây là nguồn xác nhận đáng tin duy nhất,
   * đóng vai trò tương đương vnp_SecureHash của VNPay.
   * @param {string} orderInvoiceNumber — chính là txnRef (session._id)
   */
  async fetchOrderStatus(orderInvoiceNumber) {
    const client = buildSepayClient();
    const response = await client.order.retrieve(orderInvoiceNumber);
    // response.data là body JSON thô từ SePay API, bọc trong { data: {...} }
    // (xác nhận qua log thực tế: { data: { order_status: "CAPTURED", ... } }) —
    // cần bóc lớp "data" ngoài cùng này để lấy đúng object chi tiết đơn hàng.
    return response.data?.data ?? response.data;
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
   * KHÁC với VNPAY trước đây: hàm này KHÔNG nhận amount/trạng thái từ tham số
   * URL callback (success_url/error_url) vì SDK SePay không cung cấp cách
   * verify chữ ký cho các callback đó — tin theo tham số URL sẽ cho phép giả
   * mạo (tự sửa URL thành "đã thanh toán"). Thay vào đó, hàm luôn tự gọi
   * [fetchOrderStatus] để lấy amount + trạng thái THẬT trực tiếp từ SePay.
   *
   * @param {string} txnRef — order_invoice_number (chính là session._id)
   * @returns {Promise<{ RspCode: string, Message: string, orderCodes?: string[] }>}
   */
  async confirmPayment(txnRef) {
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

    // 3. Tra cứu trạng thái THẬT từ SePay — nguồn tin cậy duy nhất.
    // CHÚ Ý: tên field đọc dưới đây (order_status/status, transaction_id,
    // amount, payment_method) dựa theo suy luận hợp lý nhất từ tài liệu công
    // khai hiện có (README SDK không mô tả đầy đủ response của order.retrieve).
    // Log toàn bộ response ra để đối chiếu và chỉnh field cho đúng ngay khi
    // chạy thử với merchant_id/secret_key thật lần đầu.
    let sepayOrder;
    try {
      sepayOrder = await this.fetchOrderStatus(txnRef);
      console.log(`[PaymentService] SePay order.retrieve(${txnRef}) =`, JSON.stringify(sepayOrder));
    } catch (err) {
      console.error(`[PaymentService] fetchOrderStatus lỗi cho ${txnRef}:`, err.message);
      return { RspCode: "99", Message: "Không tra cứu được trạng thái giao dịch từ SePay" };
    }

    const rawStatus = String(sepayOrder?.order_status || sepayOrder?.status || "").toUpperCase();
    // "CAPTURED" là trạng thái thành công thật sự trả về từ order.retrieve
    // (xác nhận qua log thực tế môi trường sandbox) — SDK/docs không liệt kê
    // rõ field này nên giữ nguyên các giá trị suy đoán ban đầu (SUCCESS/PAID/
    // COMPLETED) phòng trường hợp production trả khác.
    const isSuccess = ["SUCCESS", "PAID", "COMPLETED", "CAPTURED"].includes(rawStatus);
    const isFinalFailure = ["FAILED", "CANCELLED", "EXPIRED", "ERROR"].includes(rawStatus);

    if (!isSuccess && !isFinalFailure) {
      // Vẫn đang chờ khách quét mã/chuyển khoản — session giữ nguyên PENDING,
      // không claim/không coi là thất bại.
      return { RspCode: "02", Message: `Payment status is still ${rawStatus || "unknown"}` };
    }

    // 4. Kiểm tra số tiền khớp với session (khi SePay có trả về amount).
    const returnedAmount = sepayOrder?.order_amount ?? sepayOrder?.amount;
    if (isSuccess && returnedAmount !== undefined) {
      if (Math.round(session.total_amount) !== Math.round(Number(returnedAmount))) {
        return { RspCode: "04", Message: "Invalid amount" };
      }
    }

    // 5. Claim nguyên tử session (PENDING -> PROCESSING) — chống xử lý trùng
    // khi callback + polling cùng gọi confirmPayment gần như đồng thời.
    const claimedSession = await paymentSessionRepository.claimPending(txnRef);
    if (!claimedSession) {
      const latest = await paymentSessionRepository.findById(txnRef);
      if (latest?.status === "PAID") {
        return { RspCode: "02", Message: "Order already confirmed" };
      }
      if (latest?.status === "FAILED") {
        return { RspCode: "02", Message: "Order already failed" };
      }
      return { RspCode: "02", Message: "Payment is already being processed" };
    }

    const transactionId = sepayOrder?.transaction_id || sepayOrder?.id || null;
    const paymentMethod = sepayOrder?.payment_method || null;

    if (isSuccess) {
      return await this._handleSuccessPayment(claimedSession, { transactionId, paymentMethod, rawStatus });
    } else {
      return await this._handleFailedPayment(claimedSession, { transactionId, rawStatus });
    }
  }

  /**
   * Xác nhận kết quả thanh toán từ VNPAY (return URL / IPN) và thực hiện các
   * tác vụ sau thanh toán — tương tự [confirmPayment] (SePay) nhưng VNPAY
   * KHÔNG có API tra cứu lại trạng thái đơn hàng như SePay, nên phải tin theo
   * tham số trả về trong URL callback SAU KHI đã xác thực chữ ký
   * (vnp_SecureHash) qua [verifyReturnUrl]/[verifyIpnCall] ở controller.
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
  async confirmVnpayPayment({ txnRef, amount, responseCode, transactionStatus, transactionNo, bankCode }) {
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

    // 4. Claim nguyên tử session (PENDING -> PROCESSING) để đảm bảo chỉ 1 trong 2
    // callback VNPAY (return URL + IPN) — có thể tới gần như đồng thời — được xử lý.
    const claimedSession = await paymentSessionRepository.claimPending(txnRef);
    if (!claimedSession) {
      const latest = await paymentSessionRepository.findById(txnRef);
      if (latest?.status === "PAID") {
        return { RspCode: "02", Message: "Order already confirmed" };
      }
      if (latest?.status === "FAILED") {
        return { RspCode: "02", Message: "Order already failed" };
      }
      return { RspCode: "02", Message: "Payment is already being processed" };
    }

    // 5. Kiểm tra trạng thái giao dịch
    const isSuccess = responseCode === "00" && (transactionStatus || responseCode) === "00";

    if (isSuccess) {
      return await this._handleSuccessPayment(claimedSession, {
        transactionId: transactionNo,
        paymentMethod: bankCode,
        rawStatus: responseCode,
      });
    } else {
      return await this._handleFailedPayment(claimedSession, {
        transactionId: transactionNo,
        rawStatus: responseCode,
      });
    }
  }

  /**
   * Xử lý thanh toán thành công — tạo orders thực tế từ session.
   * @private
   */
  async _handleSuccessPayment(session, { transactionId, paymentMethod, rawStatus }) {
    // 1. Gom nhóm items theo shop_id
    const itemsByShop = new Map();
    for (const item of session.items) {
      const key = item.shop_id.toString();
      if (!itemsByShop.has(key)) itemsByShop.set(key, []);
      itemsByShop.get(key).push(item);
    }

    // 1b. Trừ tồn kho nguyên tử cho toàn bộ item trước khi tạo order — tiền đã
    // thu qua VNPAY nên nếu hết hàng vẫn phải tạo đơn (không thể huỷ giao dịch),
    // nhưng ta vẫn cần cập nhật đúng tồn kho / rollback nếu có lỗi khác xảy ra.
    const stockClaims = [];
    try {
      for (const item of session.items) {
        try {
          await orderService._claimStock(item.variant_id, item.quantity);
          stockClaims.push({ variantId: item.variant_id, quantity: item.quantity });
        } catch (stockErr) {
          // Hết hàng sau khi đã thanh toán — vẫn ghi log nhưng không chặn tạo đơn,
          // vì tiền khách đã bị trừ qua VNPAY và không thể tự động hoàn tiền ở đây.
          console.error(`[PaymentService] Insufficient stock for variant ${item.variant_id} on paid session ${session._id}:`, stockErr.message);
        }
      }
    } catch (err) {
      console.error("[PaymentService] Unexpected error while claiming stock:", err.message);
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
        payment_method: session.gateway || "sepay",
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
      socketService.emitNewOrder(shopId, order);
      const gatewayLabel = session.gateway === "vnpay" ? "VNPay" : "SePay";
      notificationService.notifyUser(session.user_id, {
        title: "Thanh toán thành công",
        body: `Đơn hàng #${order.order_code} đã thanh toán qua ${gatewayLabel} và được tiếp nhận.`,
        type: "order",
        data: { order_id: String(order._id), order_status: order.order_status },
      });
      shopIndex++;
    }

    // 3. Xoá khỏi giỏ hàng đúng những sản phẩm vừa thanh toán (không xoá toàn
    // bộ giỏ hàng, vì "Mua ngay" thanh toán 1 sản phẩm không nằm trong giỏ
    // hàng thật — xoá hết sẽ làm mất các sản phẩm khác khách đã thêm trước đó).
    const activeCart = await cartModel.findOne({
      user_id: session.user_id,
      status: "active",
      deleted_at: null,
    });
    if (activeCart) {
      const paidKeys = new Set(
        session.items.map((it) =>
          buildCartItemConfigKey(
            String(it.product_id),
            String(it.variant_id),
            (it.selected_options || []).map((o) => o.option_id),
          ),
        ),
      );

      const existingCartItems = await cartItemModel.find({ cart_id: activeCart._id, deleted_at: null });
      const idsToDelete = existingCartItems
        .filter((ci) =>
          paidKeys.has(
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

      const remainingItems = await cartItemModel.find({ cart_id: activeCart._id, deleted_at: null });
      activeCart.cart_total = remainingItems.reduce((sum, it) => sum + it.subtotal, 0);
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
    if (session.gateway === "vnpay") {
      session.vnp_transaction_no = transactionId || null;
      session.vnp_bank_code = paymentMethod || null;
      session.vnp_response_code = rawStatus || null;
    } else {
      session.sepay_transaction_id = transactionId || null;
      session.sepay_payment_method = paymentMethod || null;
      session.sepay_status = rawStatus || null;
    }
    session.paid_at = new Date();
    session.order_ids = createdOrders.map((o) => o._id);
    await session.save();

    // Send notifications for each order
    for (const order of createdOrders) {
      try {
        await notificationService.notify({
          userId: session.user_id,
          type: NOTIFICATION_TYPES.PAYMENT_SUCCESS,
          title: "Thanh toán thành công",
          message: `Đơn hàng ${order.order_code} đã được thanh toán thành công`,
          orderId: order._id,
          data: {
            orderId: order._id.toString(),
            type: NOTIFICATION_TYPES.PAYMENT_SUCCESS,
          },
        });
      } catch (notifyErr) {
        console.error(`[PaymentService] Notification error for order ${order.order_code}:`, notifyErr.message);
      }
    }

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
  async _handleFailedPayment(session, { transactionId, rawStatus }) {
    session.status = "FAILED";
    if (session.gateway === "vnpay") {
      session.vnp_transaction_no = transactionId || null;
      session.vnp_response_code = rawStatus || null;
    } else {
      session.sepay_transaction_id = transactionId || null;
      session.sepay_status = rawStatus || null;
    }
    await session.save();

    const gatewayLabel = session.gateway === "vnpay" ? "VNPay" : "SePay";
    try {
      await notificationService.notify({
        userId: session.user_id,
        type: NOTIFICATION_TYPES.PAYMENT_FAILED,
        title: "Thanh toán thất bại",
        message: `Giao dịch thanh toán ${gatewayLabel} của bạn đã không thành công hoặc bị hủy.`,
        data: {
          sessionId: session._id.toString(),
          type: NOTIFICATION_TYPES.PAYMENT_FAILED,
        },
      });
    } catch (notifyErr) {
      console.error(`[PaymentService] Notification error for failed payment session ${session._id}:`, notifyErr.message);
    }

    return { RspCode: "00", Message: "Payment failed recorded" };
  }
}

module.exports = new PaymentService();
