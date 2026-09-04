"use strict";

const { userModel } = require("../models/user.model");
const paymentService = require("../services/payment.service");

// ─── Helper ───────────────────────────────────────────────────────────────────

/**
 * Lấy userModel document từ Firebase UID trong JWT đã decode bởi firebaseAuth middleware.
 * @param {import('express').Request} req
 * @returns {Promise<Document|null>}
 */
async function resolveUser(req) {
  return userModel.findOne({ firebase_uid: req.user.uid, deleted_at: null });
}

// ─── Handlers ─────────────────────────────────────────────────────────────────

/**
 * POST /api/payments/sepay
 * Tạo payment session & biểu mẫu thanh toán SePay từ giỏ hàng hiện tại.
 *
 * Body: { address_id, delivery_option, voucher_code?, note?, items? }
 * `items` chỉ dùng cho "Mua ngay": khi có sẽ thanh toán đúng các sản phẩm này
 * thay vì đọc toàn bộ giỏ hàng thật của người dùng.
 *
 * Response: { status, data: { checkout_url, checkout_fields, txn_ref, total_amount } }
 * Khác VNPay: không trả về 1 URL để redirect GET, mà trả checkout_url +
 * checkout_fields để client tự dựng request POST (biểu mẫu ẩn) gửi tới SePay.
 */
exports.createSepayPayment = async (req, res) => {
  try {
    const user = await resolveUser(req);
    if (!user) {
      return res.status(404).json({ status: "error", msg: "Không tìm thấy tài khoản" });
    }

    const {
      address_id: addressId,
      delivery_option: deliveryOption = "standard",
      voucher_code: voucherCode,
      note,
      locale,
      items,
    } = req.body;

    if (!addressId) {
      return res.status(400).json({ status: "error", msg: "Thiếu địa chỉ giao hàng" });
    }

    const { checkoutUrl, checkoutFields, txnRef, totalAmount } = await paymentService.createPaymentUrl(req, user, {
      addressId,
      deliveryOption,
      voucherCode,
      note,
      locale,
      items,
    });

    return res.status(200).json({
      status: "success",
      data: {
        checkout_url: checkoutUrl,
        checkout_fields: checkoutFields,
        txn_ref: txnRef,
        total_amount: totalAmount,
        orders: [], // Đơn hàng thực tế chỉ được tạo sau khi xác nhận SePay đã thanh toán
      },
    });
  } catch (err) {
    console.error("[createSepayPayment]", err.message);
    return res.status(400).json({ status: "error", msg: err.message || "Lỗi tạo yêu cầu thanh toán" });
  }
};

/**
 * POST /api/payments/vnpay
 * Tạo payment session & URL thanh toán VNPAY từ giỏ hàng hiện tại.
 *
 * Body: { address_id, delivery_option, voucher_code?, note?, locale?, items? }
 * Response: { status, data: { payment_url, txn_ref, total_amount } }
 */
exports.createVnpayPayment = async (req, res) => {
  try {
    const user = await resolveUser(req);
    if (!user) {
      return res.status(404).json({ status: "error", msg: "Không tìm thấy tài khoản" });
    }

    const {
      address_id: addressId,
      delivery_option: deliveryOption = "standard",
      voucher_code: voucherCode,
      note,
      locale,
      items,
    } = req.body;

    if (!addressId) {
      return res.status(400).json({ status: "error", msg: "Thiếu địa chỉ giao hàng" });
    }

    const { paymentUrl, txnRef, totalAmount } = await paymentService.createVnpayPaymentUrl(req, user, {
      addressId,
      deliveryOption,
      voucherCode,
      note,
      locale,
      items,
    });

    return res.status(200).json({
      status: "success",
      data: {
        payment_url: paymentUrl,
        txn_ref: txnRef,
        total_amount: totalAmount,
        orders: [], // Đơn hàng thực tế chỉ được tạo sau khi VNPAY callback thành công
      },
    });
  } catch (err) {
    console.error("[createVnpayPayment]", err.message);
    return res.status(400).json({ status: "error", msg: err.message || "Lỗi tạo URL thanh toán" });
  }
};

/**
 * GET /api/payment/vnpay-return
 * VNPAY chuyển hướng trình duyệt về đây sau khi user hoàn tất / hủy thanh toán.
 * Luồng mobile: WebView phát hiện URL chứa `vnp_ResponseCode` → đóng WebView.
 */
exports.vnpayReturn = async (req, res) => {
  try {
    const vnpParams = req.query;

    // verifyReturnUrl trả về { isSuccess, isVerified, message } (không phải
    // boolean) — isVerified mới là kết quả xác thực chữ ký, isSuccess là kết
    // quả giao dịch (đã tự kiểm tra riêng trong confirmVnpayPayment).
    const verifyResult = paymentService.verifyReturnUrl(vnpParams);
    if (!verifyResult.isVerified) {
      return res.status(400).json({ status: "error", msg: "Chữ ký không hợp lệ" });
    }

    const confirmResult = await paymentService.confirmVnpayPayment({
      txnRef: vnpParams.vnp_TxnRef,
      amount: vnpParams.vnp_Amount,
      responseCode: vnpParams.vnp_ResponseCode,
      transactionStatus: vnpParams.vnp_TransactionStatus,
      transactionNo: vnpParams.vnp_TransactionNo,
      bankCode: vnpParams.vnp_BankCode,
    });
    const isSuccess = confirmResult.RspCode === "00" && !!confirmResult.orderCodes;

    const ua = String(req.headers["user-agent"] || "");
    const isMobile =
      /Android|iPhone|iPad|iPod|Expo|ReactNative/i.test(ua) ||
      vnpParams.source === "app";

    if (isMobile) {
      return res.status(200).send(_buildResultHtml(isSuccess, vnpParams.vnp_TxnRef || ""));
    }

    return res.status(200).json({
      status: "success",
      data: {
        success: isSuccess,
        vnp_ResponseCode: vnpParams.vnp_ResponseCode,
        vnp_TxnRef: vnpParams.vnp_TxnRef,
        vnp_Amount: vnpParams.vnp_Amount,
        vnp_TransactionNo: vnpParams.vnp_TransactionNo,
        confirm: confirmResult,
      },
    });
  } catch (err) {
    console.error("[vnpayReturn]", err.message);
    return res.status(500).json({ status: "error", msg: "Lỗi hệ thống" });
  }
};

/**
 * GET /api/payment/vnpay-ipn
 * VNPAY gọi server-to-server (IPN) để thông báo kết quả giao dịch.
 * Phải trả về { RspCode, Message } theo đặc tả VNPAY.
 */
exports.vnpayIpn = async (req, res) => {
  try {
    const vnpParams = req.query;

    // Cũng trả về { isSuccess, isVerified, message } — xem chú thích ở vnpayReturn.
    const verifyResult = paymentService.verifyIpnCall(vnpParams);
    if (!verifyResult.isVerified) {
      return res.status(200).json({ RspCode: "97", Message: "Invalid checksum" });
    }

    const result = await paymentService.confirmVnpayPayment({
      txnRef: vnpParams.vnp_TxnRef,
      amount: vnpParams.vnp_Amount,
      responseCode: vnpParams.vnp_ResponseCode,
      transactionStatus: vnpParams.vnp_TransactionStatus,
      transactionNo: vnpParams.vnp_TransactionNo,
      bankCode: vnpParams.vnp_BankCode,
    });

    return res.status(200).json(result);
  } catch (err) {
    console.error("[vnpayIpn]", err.message);
    return res.status(200).json({ RspCode: "99", Message: err.message });
  }
};

/**
 * GET /api/payment/sepay-return?txnRef=...
 * SePay chuyển hướng trình duyệt về đây sau khi khách hoàn tất / hủy thanh
 * toán (dùng chung 1 URL cho cả success_url/error_url/cancel_url vì bản thân
 * URL không mang thông tin đáng tin — server luôn tự tra cứu trạng thái thật
 * qua [paymentService.confirmPayment] thay vì đọc query string).
 * Luồng mobile: WebView phát hiện URL này → đóng lại, Flutter gọi tiếp
 * /api/payment/sepay-verify để lấy kết quả cuối cùng.
 */
exports.sepayReturn = async (req, res) => {
  try {
    const txnRef = req.query.txnRef || req.query.order_invoice_number;
    if (!txnRef) {
      return res.status(400).json({ status: "error", msg: "Thiếu mã giao dịch" });
    }

    const confirmResult = await paymentService.confirmPayment(txnRef);
    const isSuccess = confirmResult.RspCode === "00" && !!confirmResult.orderCodes;

    // Detect mobile WebView request (User-Agent hoặc query param)
    const ua = String(req.headers["user-agent"] || "");
    const isMobile =
      /Android|iPhone|iPad|iPod|Expo|ReactNative/i.test(ua) ||
      req.query.source === "app";

    if (isMobile) {
      // Trả về HTML đơn giản — WebView sẽ phát hiện URL này, đóng lại và
      // gọi API xác minh từ phía Flutter. Page này chỉ là trang "cầu nối".
      return res.status(200).send(_buildResultHtml(isSuccess, txnRef));
    }

    return res.status(200).json({
      status: "success",
      data: {
        success: isSuccess,
        txn_ref: txnRef,
        confirm: confirmResult,
      },
    });
  } catch (err) {
    console.error("[sepayReturn]", err.message);
    return res.status(500).json({ status: "error", msg: "Lỗi hệ thống" });
  }
};

/**
 * GET /api/payment/sepay-verify?txnRef=...
 * Flutter gọi API này sau khi WebView đóng để lấy kết quả giao dịch cuối
 * cùng. Cũng TỰ tra cứu lại trạng thái từ SePay (qua confirmPayment) trước
 * khi trả kết quả, phòng trường hợp khách đóng WebView trước khi kịp redirect
 * về success_url (ví dụ: quét mã xong nhưng thoát app quá nhanh).
 */
exports.verifyPayment = async (req, res) => {
  try {
    const user = await resolveUser(req);
    if (!user) {
      return res.status(404).json({ status: "error", msg: "Không tìm thấy tài khoản" });
    }

    const { txnRef } = req.query;
    if (!txnRef) {
      return res.status(400).json({ status: "error", msg: "Thiếu txnRef" });
    }

    const paymentSessionRepository = require("../repositories/payment_session.repository");
    let session = await paymentSessionRepository.findById(txnRef);

    if (!session) {
      return res.status(404).json({ status: "error", msg: "Không tìm thấy giao dịch" });
    }

    // Bảo mật: chỉ cho user xem session của chính họ
    if (session.user_id.toString() !== user._id.toString()) {
      return res.status(403).json({ status: "error", msg: "Không có quyền truy cập" });
    }

    // Session còn đang chờ (PENDING/PROCESSING) — thử tra cứu lại ngay, phòng
    // trường hợp WebView đóng trước khi return URL kịp gọi confirm. Chỉ áp
    // dụng cho SePay (có API tra cứu trạng thái); VNPAY không có API tương
    // đương nên phải chờ đúng return URL/IPN gọi confirm.
    if (session.status === "PENDING" && session.gateway === "sepay") {
      await paymentService.confirmPayment(txnRef);
      session = await paymentSessionRepository.findById(txnRef);
    }

    const { orderModel } = require("../models/order.model");
    let orderCodes = [];
    if (session.status === "PAID" && session.order_ids && session.order_ids.length > 0) {
      const orders = await orderModel.find({ _id: { $in: session.order_ids } });
      orderCodes = orders.map((o) => o.order_code);
    }

    return res.status(200).json({
      status: "success",
      data: {
        session_status: session.status,
        total_amount: session.total_amount,
        paid_at: session.paid_at,
        order_codes: orderCodes,
        sepay_status: session.sepay_status,
        vnp_response_code: session.vnp_response_code,
      },
    });
  } catch (err) {
    console.error("[verifyPayment]", err.message);
    return res.status(500).json({ status: "error", msg: "Lỗi hệ thống" });
  }
};

/**
 * POST /api/payment/sepay-ipn
 * SePay gọi server-to-server khi giao dịch có biến động (không phụ thuộc
 * trình duyệt khách còn mở hay không — khác với sepay-return/sepay-verify).
 * KHÔNG tin bất kỳ trường nào trong body vì SDK không cung cấp cách verify
 * chữ ký cho IPN — chỉ đọc order_invoice_number để biết cần tra cứu session
 * nào, mọi thứ khác lấy từ [paymentService.confirmPayment] (tự gọi lại
 * order.retrieve để lấy trạng thái THẬT từ SePay).
 */
exports.sepayIpn = async (req, res) => {
  try {
    const txnRef = req.body?.order_invoice_number || req.body?.orderInvoiceNumber || req.query.order_invoice_number;
    if (!txnRef) {
      return res.status(400).json({ status: "error", msg: "Thiếu order_invoice_number" });
    }

    await paymentService.confirmPayment(txnRef);
    return res.status(200).json({ status: "success" });
  } catch (err) {
    console.error("[sepayIpn]", err.message);
    // Vẫn trả 200 để SePay không lặp lại vô hạn cho lỗi phía ta không tự phục hồi được;
    // giao dịch vẫn được đối soát lại qua sepay-return/sepay-verify khi khách quay lại app.
    return res.status(200).json({ status: "error", msg: "Lỗi xử lý IPN" });
  }
};

// ─── Private Helpers ──────────────────────────────────────────────────────────

/**
 * Tạo HTML trang "cầu nối" cho mobile WebView.
 * WebView sẽ phát hiện URL chứa `vnp_ResponseCode` và đóng WebView ngay.
 * Page này chỉ hiện ra nếu redirect chậm hoặc deep-link không hoạt động.
 */
function _buildResultHtml(isSuccess, txnRef) {
  const statusClass = isSuccess ? "success" : "failed";
  const statusText = isSuccess ? "Thanh toán thành công" : "Thanh toán không thành công";
  const statusSub = isSuccess
    ? "Đơn hàng của bạn đang được xử lý. Quay lại ứng dụng để xem chi tiết."
    : "Thanh toán không thành công hoặc đã bị hủy. Quay lại ứng dụng để thử lại.";

  return `<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Kết quả thanh toán</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      background: #0f172a;
      color: #e2e8f0;
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      padding: 24px;
    }
    .card {
      background: #1e293b;
      border-radius: 20px;
      padding: 32px 24px;
      max-width: 400px;
      width: 100%;
      text-align: center;
      border: 1px solid rgba(148, 163, 184, 0.15);
    }
    .icon { font-size: 56px; margin-bottom: 16px; }
    .title { font-size: 20px; font-weight: 700; margin-bottom: 8px; }
    .success { color: #22c55e; }
    .failed { color: #f97316; }
    .sub { font-size: 13px; color: #94a3b8; line-height: 1.6; margin-bottom: 24px; }
  </style>
</head>
<body>
  <div class="card">
    <div class="icon">${isSuccess ? "✅" : "❌"}</div>
    <div class="title ${statusClass}">${statusText}</div>
    <div class="sub">${statusSub}</div>
  </div>
</body>
</html>`;
}
