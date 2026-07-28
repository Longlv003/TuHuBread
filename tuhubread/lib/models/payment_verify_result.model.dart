/// Model kết quả verify giao dịch — response của GET /api/payment/vnpay-verify.
class PaymentVerifyResult {
  final String sessionStatus; // PENDING | PAID | FAILED | EXPIRED
  final double totalAmount;
  final DateTime? paidAt;
  final List<String> orderCodes;
  final String? vnpResponseCode;

  const PaymentVerifyResult({
    required this.sessionStatus,
    required this.totalAmount,
    this.paidAt,
    required this.orderCodes,
    this.vnpResponseCode,
  });

  bool get isPaid => sessionStatus == 'PAID';
  bool get isFailed => sessionStatus == 'FAILED';
  bool get isPending => sessionStatus == 'PENDING';

  factory PaymentVerifyResult.fromJson(Map<String, dynamic> json) {
    final codes = (json['order_codes'] as List? ?? [])
        .map((e) => e.toString())
        .toList();
    final paidAtStr = json['paid_at'] as String?;
    return PaymentVerifyResult(
      sessionStatus: json['session_status'] as String? ?? 'PENDING',
      totalAmount: (json['total_amount'] as num? ?? 0).toDouble(),
      paidAt: paidAtStr != null ? DateTime.tryParse(paidAtStr) : null,
      orderCodes: codes,
      vnpResponseCode: json['vnp_response_code'] as String?,
    );
  }
}
