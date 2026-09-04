import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../flavors.dart';

/// Kết quả trả về khi WebView đóng.
class SePayResult {
  /// `true` nếu SePay redirect về với trạng thái thanh toán thành công.
  /// Chỉ mang tính GỢI Ý (phát hiện qua URL) — [CheckoutPage] vẫn phải gọi
  /// verify để lấy trạng thái THẬT từ server trước khi coi là đã thanh toán.
  final bool reachedReturnUrl;

  /// txnRef (order_invoice_number) — dùng để gọi verifyAfterWebView().
  final String? txnRef;

  const SePayResult({required this.reachedReturnUrl, this.txnRef});
}

/// Trang WebView để thực hiện giao dịch qua cổng SePay (quét mã VietQR /
/// Napas chuyển khoản).
///
/// Khác VNPay trước đây: SePay yêu cầu **POST** biểu mẫu (kèm chữ ký
/// HMAC-SHA256 đã backend tính sẵn) tới [checkoutUrl], không phải chỉ mở 1
/// URL GET có sẵn — nên WebView phải load bằng [URLRequest] có `method` và
/// `body` thay vì `initialUrlRequest` đơn thuần.
///
/// Luồng:
///   1. POST [checkoutFields] (đã ký) tới [checkoutUrl].
///   2. Lắng nghe URL navigation — khi phát hiện `/payment/sepay-return`
///      (kèm `txnRef` do backend tự đính vào success_url/error_url/cancel_url
///      lúc tạo biểu mẫu) → đóng WebView.
///   3. CheckoutPage dùng txnRef gọi `paymentCubit.verifyAfterWebView()` —
///      hàm đó TỰ tra cứu lại trạng thái thật từ SePay, không tin theo URL.
class SePayPaymentPage extends StatefulWidget {
  final String checkoutUrl;
  final Map<String, dynamic> checkoutFields;
  final String txnRef;

  const SePayPaymentPage({
    super.key,
    required this.checkoutUrl,
    required this.checkoutFields,
    required this.txnRef,
  });

  @override
  State<SePayPaymentPage> createState() => _SePayPaymentPageState();
}

class _SePayPaymentPageState extends State<SePayPaymentPage> {
  bool _isLoading = true;
  bool _hasHandled = false; // Tránh xử lý redirect 2 lần

  /// Mã hoá [checkoutFields] thành body dạng
  /// application/x-www-form-urlencoded cho request POST.
  Uint8List _buildPostBody() {
    final encoded = widget.checkoutFields.entries
        .map(
          (e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent('${e.value}')}',
        )
        .join('&');
    return Uint8List.fromList(utf8.encode(encoded));
  }

  /// Kiểm tra URL có phải là return URL của SePay không (đã gắn kèm txnRef ở
  /// backend). Khi đúng, đóng WebView.
  void _handleUrl(String url) {
    if (_hasHandled) return;

    final isReturnUrl = url.contains('/payment/sepay-return');
    if (!isReturnUrl) return;

    final uri = Uri.tryParse(url);
    if (uri == null) return;

    _hasHandled = true;
    final txnRef = uri.queryParameters['txnRef'] ?? widget.txnRef;

    if (mounted) {
      Navigator.of(context).pop(
        SePayResult(reachedReturnUrl: true, txnRef: txnRef),
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
                  url: WebUri(widget.checkoutUrl),
                  method: 'POST',
                  headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                  },
                  body: _buildPostBody(),
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
                // Chỉ bypass SSL certificate validation ở môi trường dev (SePay sandbox
                // có thể dùng chuỗi CA mới mà 1 số máy ảo/thiết bị cũ chưa cập nhật kịp) —
                // production luôn phải xác thực chứng chỉ thật để tránh MITM trên màn
                // hình thanh toán.
                onReceivedServerTrustAuthRequest: (controller, challenge) async {
                  if (F.appFlavor == Flavor.development) {
                    debugPrint('[SePay] SSL challenge from: ${challenge.protectionSpace.host} — proceeding (dev only)');
                    return ServerTrustAuthResponse(
                      action: ServerTrustAuthResponseAction.PROCEED,
                    );
                  }
                  debugPrint('[SePay] SSL challenge from: ${challenge.protectionSpace.host} — rejecting (production)');
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
                  debugPrint('[SePayWebView] Error: ${error.description} for ${request.url}');
                },
                // Renderer WebView (Chromium) có thể crash giữa chừng trên 1 số máy ảo/
                // thiết bị cũ khi tải trang cổng thanh toán nặng — WebView lúc này đã
                // "chết" hẳn, không thể tiếp tục dùng. Phải đóng ngay và coi như thất bại
                // (an toàn hơn là để app treo) — CheckoutPage sẽ hiện dialog thất bại,
                // khách có thể bắt đầu lại giao dịch từ đầu.
                onRenderProcessGone: (controller, detail) {
                  debugPrint('[SePayWebView] Renderer process gone: $detail');
                  if (_hasHandled) return;
                  _hasHandled = true;
                  if (mounted) {
                    Navigator.of(context).pop(
                      const SePayResult(reachedReturnUrl: false),
                    );
                  }
                },
                // CHỦ Ý: không gọi _handleUrl() ở đây và pop ngay — nếu redirect về
                // return URL là do JS phía SePay gọi (window.location.href) chứ không
                // phải server trả HTTP redirect, shouldOverrideUrlLoading sẽ bắt được
                // TRƯỚC KHI request thật sự được gửi đi. Pop/dispose WebView ngay lúc
                // này có thể huỷ luôn request đó — khiến app đọc được đúng txnRef từ
                // URL nhưng backend KHÔNG BAO GIỜ nhận được /payment/sepay-return để
                // xác nhận giao dịch. Phải để WebView tự load xong URL đó rồi mới đóng
                // ở onLoadStart/onLoadStop bên dưới.
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
