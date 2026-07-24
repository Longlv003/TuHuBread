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
 * POST /api/payments/vnpay
 * Tạo payment session & URL thanh toán VNPAY từ giỏ hàng hiện tại.
 *
 * Body: { address_id, delivery_option, voucher_code?, note?, locale? }
 * Response: { status, data: { payment_url, total_amount, session_id } }
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
    } = req.body;

    if (!addressId) {
      return res.status(400).json({ status: "error", msg: "Thiếu địa chỉ giao hàng" });
    }

    const { paymentUrl, totalAmount } = await paymentService.createPaymentUrl(req, user, {
      addressId,
      deliveryOption,
      voucherCode,
      note,
      locale,
    });

    return res.status(200).json({
      status: "success",
      data: {
        payment_url: paymentUrl,
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
 * Luồng web: trả về JSON hoặc redirect trang kết quả.
 */
exports.vnpayReturn = async (req, res) => {
  try {
    const vnpParams = req.query;

    // Xác thực chữ ký
    const isValid = paymentService.verifyReturnUrl(vnpParams);
    if (!isValid) {
      return res.status(400).json({ status: "error", msg: "Chữ ký không hợp lệ" });
    }

    const isSuccess = vnpParams.vnp_ResponseCode === "00";

    // Confirm & tạo orders nếu thành công
    const confirmResult = await paymentService.confirmPayment({
      txnRef: vnpParams.vnp_TxnRef,
      amount: vnpParams.vnp_Amount,
      responseCode: vnpParams.vnp_ResponseCode,
      transactionStatus: vnpParams.vnp_TransactionStatus,
      transactionNo: vnpParams.vnp_TransactionNo,
      bankCode: vnpParams.vnp_BankCode,
    });

    // Detect mobile WebView request (User-Agent hoặc query param)
    const ua = String(req.headers["user-agent"] || "");
    const isMobile =
      /Android|iPhone|iPad|iPod|Expo|ReactNative/i.test(ua) ||
      vnpParams.source === "app";

    if (isMobile) {
      // Trả về HTML đơn giản — WebView sẽ phát hiện URL này, đóng lại và
      // gọi API xác minh từ phía Flutter. Page này chỉ là trang "cầu nối".
      return res.status(200).send(_buildResultHtml(isSuccess, vnpParams.vnp_TxnRef || ""));
    }

    // Web response
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

    if (!paymentService.verifyIpnCall(vnpParams)) {
      return res.status(200).json({ RspCode: "97", Message: "Invalid checksum" });
    }

    const result = await paymentService.confirmPayment({
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
 * GET /api/payment/vnpay-verify?txnRef=...
 * Flutter gọi API này sau khi WebView đóng để lấy kết quả giao dịch cuối cùng.
 * Trả về trạng thái session và danh sách order codes.
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
    const session = await paymentSessionRepository.findById(txnRef);

    if (!session) {
      return res.status(404).json({ status: "error", msg: "Không tìm thấy giao dịch" });
    }

    // Bảo mật: chỉ cho user xem session của chính họ
    if (session.user_id.toString() !== user._id.toString()) {
      return res.status(403).json({ status: "error", msg: "Không có quyền truy cập" });
    }

    // Nếu session vẫn PENDING (IPN chưa về), thử lấy từ order để populate order_codes
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
        vnp_response_code: session.vnp_response_code,
      },
    });
  } catch (err) {
    console.error("[verifyPayment]", err.message);
    return res.status(500).json({ status: "error", msg: "Lỗi hệ thống" });
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
