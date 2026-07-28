import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

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
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  bool _hasHandled = false; // Tránh xử lý redirect 2 lần

  /// Kiểm tra URL có phải là return URL của VNPAY không.
  /// Khi đúng, trích xuất kết quả và đóng WebView.
  void _handleUrl(String url) {
    if (_hasHandled) return;

    final isReturnUrl =
        url.contains('/payment/vnpay-return') ||
        url.contains('/payments/vnpay/return');

    if (!isReturnUrl) return;

    final uri = Uri.tryParse(url);
    if (uri == null) return;

    // Chỉ xử lý khi có `vnp_ResponseCode` — tránh bắt nhầm khi URL chứa
    // `vnp_ReturnUrl` như một tham số (VNPAY embed returnUrl vào payment URL)
    if (!uri.queryParameters.containsKey('vnp_ResponseCode')) return;

    _hasHandled = true;

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
                  // Cho phép load mixed content (HTTP trong HTTPS)
                  mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                  // Không kiểm tra SSL trong dev/sandbox
                  allowFileAccessFromFileURLs: true,
                  allowUniversalAccessFromFileURLs: true,
                  clearCache: true,
                ),
                onWebViewCreated: (controller) {
                  _webViewController = controller;
                },
                // ★ KEY FIX: bypass SSL certificate validation cho VNPAY sandbox
                onReceivedServerTrustAuthRequest: (controller, challenge) async {
                  debugPrint('[VnPay] SSL challenge from: ${challenge.protectionSpace.host} — proceeding');
                  return ServerTrustAuthResponse(
                    action: ServerTrustAuthResponseAction.PROCEED,
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
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  final url = navigationAction.request.url?.toString() ?? '';
                  _handleUrl(url);
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
