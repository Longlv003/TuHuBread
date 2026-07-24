import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tuhubread/models/order_result.model.dart';
import 'package:tuhubread/models/payment_verify_result.model.dart';

import '../../core/result.dart';
import '../../repositories/payment_repository.dart';
import 'payment_state.dart';

/// PaymentCubit quản lý toàn bộ luồng thanh toán VNPay:
///  1. [initiateVnpayPayment] → gọi backend tạo PaymentSession + URL
///  2. [verifyAfterWebView]   → gọi backend verify kết quả sau khi WebView đóng
class PaymentCubit extends Cubit<PaymentState> {
  final PaymentRepository _repository;

  PaymentCubit({required PaymentRepository repository})
    : _repository = repository,
      super(const PaymentInitial());

  /// Bước 1: Tạo URL thanh toán VNPay.
  ///
  /// Phát [PaymentLoading] → khi có URL phát [PaymentUrlReady].
  /// Khi gặp lỗi phát [PaymentError].
  Future<void> initiateVnpayPayment({
    required String addressId,
    required String deliveryOption,
    String? voucherCode,
    String? note,
  }) async {
    emit(const PaymentLoading());

    final result = await _repository.createVnpayPayment(
      addressId: addressId,
      deliveryOption: deliveryOption,
      voucherCode: voucherCode,
      note: note,
    );

    switch (result) {
      case Success<OrderResultModel>(:final data):
        if (data.paymentUrl != null && data.paymentUrl!.isNotEmpty) {
          emit(
            PaymentUrlReady(
              paymentUrl: data.paymentUrl!,
              totalAmount: data.totalAmount,
            ),
          );
        } else {
          emit(
            const PaymentError(message: 'Backend không trả về URL thanh toán'),
          );
        }
      case Failure<OrderResultModel>(:final message):
        emit(PaymentError(message: message));
    }
  }

  /// Bước 2: Verify kết quả sau khi WebView đóng.
  ///
  /// [txnRef] là session ID được nhúng trong URL return của VNPAY.
  /// Phát [PaymentLoading] → [PaymentSuccess] hoặc [PaymentFailed].
  Future<void> verifyAfterWebView({required String txnRef}) async {
    emit(const PaymentLoading());

    final result = await _repository.verifyPayment(txnRef: txnRef);

    switch (result) {
      case Success<PaymentVerifyResult>(:final data):
        if (data.isPaid) {
          emit(PaymentSuccess(result: data));
        } else {
          emit(
            PaymentFailed(
              reason: data.isFailed
                  ? 'Giao dịch thất bại (mã: ${data.vnpResponseCode ?? "?"})'
                  : 'Giao dịch đang được xử lý',
            ),
          );
        }
      case Failure<PaymentVerifyResult>(:final message):
        emit(PaymentFailed(reason: message));
    }
  }

  /// Reset về trạng thái ban đầu (khi rời khỏi màn checkout).
  void reset() => emit(const PaymentInitial());
}
