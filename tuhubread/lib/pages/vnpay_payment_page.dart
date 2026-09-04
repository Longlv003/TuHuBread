import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../flavors.dart';

/// Kết quả trả về khi WebView đóng.
class VnPayResult {
  /// `true` nếu VNPAY redirect về với `vnp_ResponseCode=00`.
  final bool isSuccess;

  /// txnRef (session ID) từ URL callback — dùng để gọi verifyPayment.
  final String? txnRef;

  const VnPayResult({required this.isSuccess, this.txnRef});
}

/// Trang WebView để thực hiện giao dịch qua cổng VNPAY.
///
/// Luồng:
///   1. Load [paymentUrl] vào InAppWebView.
///   2. Lắng nghe URL navigation — khi phát hiện `/payment/vnpay-return`
///      và có `vnp_ResponseCode`, trích xuất txnRef & responseCode.
///   3. Đóng WebView, trả về [VnPayResult] về màn trước.
///   4. CheckoutPage dùng txnRef gọi `paymentCubit.verifyAfterWebView()`.
class VnPayPaymentPage extends StatefulWidget {
  final String paymentUrl;

  const VnPayPaymentPage({super.key, required this.paymentUrl});

  @override
  State<VnPayPaymentPage> createState() => _VnPayPaymentPageState();
}

class _VnPayPaymentPageState extends State<VnPayPaymentPage> {
  bool _isLoading = true;
  bool _hasHandled = false; // Tránh xử lý redirect 2 lần

  /// Kiểm tra URL có phải là return URL của VNPAY không.
  /// Khi đúng, trích xuất kết quả và đóng WebView.
  void _handleUrl(String url) {
    if (_hasHandled) return;

    // TODO(debug): log tạm để chẩn đoán vì sao return URL đôi khi không tới
    // được backend — xoá khi đã xác nhận ổn định.
    debugPrint('[VnPayWebView] navigating: $url');

    final isReturnUrl =
        url.contains('/payment/vnpay-return') ||
        url.contains('/payments/vnpay/return');

    if (!isReturnUrl) return;

    final uri = Uri.tryParse(url);
    if (uri == null) return;

    // Chỉ xử lý khi có `vnp_ResponseCode` — tránh bắt nhầm khi URL chứa
    // `vnp_ReturnUrl` như một tham số (VNPAY embed returnUrl vào payment URL)
    if (!uri.queryParameters.containsKey('vnp_ResponseCode')) {
      debugPrint('[VnPayWebView] matched return path but missing vnp_ResponseCode, ignoring');
      return;
    }

    _hasHandled = true;
    debugPrint('[VnPayWebView] return URL confirmed, closing WebView');

    final responseCode = uri.queryParameters['vnp_ResponseCode'];
    final txnRef = uri.queryParameters['vnp_TxnRef'];
    final isSuccess = responseCode == '00';

    if (mounted) {
      Navigator.of(context).pop(
        VnPayResult(isSuccess: isSuccess, txnRef: txnRef),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Chặn nút back vật lý Android
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(
            children: [
              InAppWebView(
                initialUrlRequest: URLRequest(
                  url: WebUri(widget.paymentUrl),
                ),
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  // Chỉ cho phép mixed content (HTTP trong HTTPS) ở môi trường dev/sandbox —
                  // production phải toàn HTTPS, không được nới lỏng.
                  mixedContentMode: F.appFlavor == Flavor.development
                      ? MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW
                      : MixedContentMode.MIXED_CONTENT_NEVER_ALLOW,
                  clearCache: true,
                ),
                // Chỉ bypass SSL certificate validation ở môi trường dev (VNPAY sandbox
                // dùng chứng chỉ test). Production luôn phải xác thực chứng chỉ thật để
                // tránh MITM trên màn hình thanh toán.
                onReceivedServerTrustAuthRequest: (controller, challenge) async {
                  if (F.appFlavor == Flavor.development) {
                    debugPrint('[VnPay] SSL challenge from: ${challenge.protectionSpace.host} — proceeding (dev only)');
                    return ServerTrustAuthResponse(
                      action: ServerTrustAuthResponseAction.PROCEED,
                    );
                  }
                  debugPrint('[VnPay] SSL challenge from: ${challenge.protectionSpace.host} — rejecting (production)');
                  return ServerTrustAuthResponse(
                    action: ServerTrustAuthResponseAction.CANCEL,
                  );
                },
                onLoadStart: (controller, url) {
                  if (!mounted) return;
                  setState(() => _isLoading = true);
                  if (url != null) _handleUrl(url.toString());
                },
                onLoadStop: (controller, url) async {
                  if (!mounted) return;
                  setState(() => _isLoading = false);
                  if (url != null) _handleUrl(url.toString());
                },
                onReceivedError: (controller, request, error) {
                  debugPrint('[VnPayWebView] Error: ${error.description} for ${request.url}');
                },
                // Renderer WebView (Chromium) có thể crash giữa chừng trên 1 số máy ảo/
                // thiết bị cũ khi tải trang cổng thanh toán nặng — WebView lúc này đã
                // "chết" hẳn, không thể tiếp tục dùng. Phải đóng ngay và coi như thất bại
                // (an toàn hơn là để app treo) — CheckoutPage sẽ hiện dialog thất bại,
                // khách có thể bắt đầu lại giao dịch từ đầu.
                onRenderProcessGone: (controller, detail) {
                  debugPrint('[VnPayWebView] Renderer process gone: $detail');
                  if (_hasHandled) return;
                  _hasHandled = true;
                  if (mounted) {
                    Navigator.of(context).pop(
                      const VnPayResult(isSuccess: false),
                    );
                  }
                },
                // CHỦ Ý: không gọi _handleUrl() ở đây và pop ngay — nếu redirect về
                // return URL là do JS phía VNPAY gọi (window.location.href) chứ không
                // phải server trả HTTP redirect, shouldOverrideUrlLoading sẽ bắt được
                // TRƯỚC KHI request thật sự được gửi đi. Pop/dispose WebView ngay lúc
                // này có thể huỷ luôn request đó — khiến app đọc được đúng vnp_TxnRef
                // từ URL nhưng backend KHÔNG BAO GIỜ nhận được /payment/vnpay-return
                // để xác nhận giao dịch (session kẹt PENDING mãi). Phải để WebView tự
                // load xong URL đó rồi mới đóng ở onLoadStart/onLoadStop bên dưới.
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  return NavigationActionPolicy.ALLOW;
                },
              ),
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFE67E22),
                    strokeWidth: 3,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
