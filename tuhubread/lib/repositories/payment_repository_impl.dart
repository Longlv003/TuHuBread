import 'package:logger/logger.dart';

import '../core/result.dart';
import '../models/order_result.model.dart';
import '../models/payment_verify_result.model.dart';
import '../services/api_service.dart';
import 'payment_repository.dart';

final _log = Logger(
  printer: PrettyPrinter(methodCount: 1, colors: true, printEmojis: true),
);

class PaymentRepositoryImpl implements PaymentRepository {
  final ApiService apiService;

  const PaymentRepositoryImpl({required this.apiService});

  @override
  Future<Result<OrderResultModel>> createVnpayPayment({
    required String addressId,
    required String deliveryOption,
    String? voucherCode,
    String? note,
  }) async {
    try {
      final res = await apiService.post('/api/payments/vnpay', {
        'address_id': addressId,
        'delivery_option': deliveryOption,
        if (voucherCode != null) 'voucher_code': voucherCode,
        if (note != null) 'note': note,
      });

      if (res['data'] != null) {
        return Success(
          OrderResultModel.fromJson(res['data'] as Map<String, dynamic>),
        );
      }
      return Failure(res['msg'] ?? 'Không thể tạo link thanh toán VNPay');
    } catch (e, s) {
      _log.e('[createVnpayPayment] Failed', error: e, stackTrace: s);
      return const Failure('Không thể kết nối đến máy chủ để thanh toán');
    }
  }

  @override
  Future<Result<PaymentVerifyResult>> verifyPayment({
    required String txnRef,
  }) async {
    try {
      final res = await apiService.get(
        '/api/payment/vnpay-verify',
        query: {'txnRef': txnRef},
      );

      if (res['data'] != null) {
        return Success(
          PaymentVerifyResult.fromJson(
            res['data'] as Map<String, dynamic>,
          ),
        );
      }
      return Failure(res['msg'] ?? 'Không thể xác minh giao dịch');
    } catch (e, s) {
      _log.e('[verifyPayment] Failed', error: e, stackTrace: s);
      return const Failure('Không thể kết nối đến máy chủ');
    }
  }
}
