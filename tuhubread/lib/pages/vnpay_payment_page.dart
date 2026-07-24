import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
///   1. Load [paymentUrl] vào WebView.
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
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasHandled = false; // Tránh xử lý redirect 2 lần

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (!mounted) return;
            setState(() => _isLoading = true);
            _handleUrl(url);
          },
          onPageFinished: (url) {
            if (!mounted) return;
            setState(() => _isLoading = false);
            _handleUrl(url);
          },
          onNavigationRequest: (request) {
            _handleUrl(request.url);
            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            // Bỏ qua lỗi tài nguyên không quan trọng
            debugPrint('[VnPayWebView] Resource error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.black12,
        title: const Text(
          'Thanh toán VNPay',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        leading: IconButton(
          tooltip: 'Hủy thanh toán',
          icon: const Icon(Icons.close_rounded, color: Color(0xFF2C3E50)),
          onPressed: () {
            if (mounted) {
              Navigator.of(context).pop(
                const VnPayResult(isSuccess: false, txnRef: null),
              );
            }
          },
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFE67E22),
                strokeWidth: 3,
              ),
            ),
        ],
      ),
    );
  }
}
