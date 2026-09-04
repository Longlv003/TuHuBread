import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tuhubread/models/order_result.model.dart';
import 'package:tuhubread/models/payment_verify_result.model.dart';

import '../../core/result.dart';
import '../../models/cart_item.model.dart';
import '../../repositories/payment_repository.dart';
import 'payment_state.dart';
import 'package:tuhubread/l10n/app_strings.dart';

/// PaymentCubit quản lý toàn bộ luồng thanh toán SePay & VNPay:
///  1. [initiateSepayPayment] / [initiateVnpayPayment] → gọi backend tạo
///     PaymentSession + biểu mẫu/URL thanh toán
///  2. [verifyAfterWebView]   → gọi backend verify kết quả sau khi WebView đóng
class PaymentCubit extends Cubit<PaymentState> {
  final PaymentRepository _repository;

  PaymentCubit({required PaymentRepository repository})
    : _repository = repository,
      super(const PaymentInitial());

  /// Bước 1: Tạo biểu mẫu thanh toán SePay.
  ///
  /// Phát [PaymentLoading] → khi có biểu mẫu phát [PaymentUrlReady].
  /// Khi gặp lỗi phát [PaymentError].
  Future<void> initiateSepayPayment({
    required String addressId,
    required String deliveryOption,
    String? voucherCode,
    String? note,
    List<CartItemModel>? items,
  }) async {
    emit(const PaymentLoading());

    final result = await _repository.createSepayPayment(
      addressId: addressId,
      deliveryOption: deliveryOption,
      voucherCode: voucherCode,
      note: note,
      items: items,
    );

    switch (result) {
      case Success<OrderResultModel>(:final data):
        if (data.checkoutUrl != null &&
            data.checkoutUrl!.isNotEmpty &&
            data.checkoutFields != null &&
            data.txnRef != null) {
          emit(
            PaymentUrlReady(
              checkoutUrl: data.checkoutUrl!,
              checkoutFields: data.checkoutFields!,
              txnRef: data.txnRef!,
              totalAmount: data.totalAmount,
            ),
          );
        } else {
          emit(
            PaymentError(message: AppStrings.current.errorNoPaymentUrl),
          );
        }
      case Failure<OrderResultModel>(:final message):
        emit(PaymentError(message: message));
    }
  }

  /// Bước 1 (VNPay): Tạo URL thanh toán VNPay.
  ///
  /// Phát [PaymentLoading] → khi có URL phát [VnpayUrlReady].
  /// Khi gặp lỗi phát [PaymentError].
  Future<void> initiateVnpayPayment({
    required String addressId,
    required String deliveryOption,
    String? voucherCode,
    String? note,
    List<CartItemModel>? items,
  }) async {
    emit(const PaymentLoading());

    final result = await _repository.createVnpayPayment(
      addressId: addressId,
      deliveryOption: deliveryOption,
      voucherCode: voucherCode,
      note: note,
      items: items,
    );

    switch (result) {
      case Success<OrderResultModel>(:final data):
        if (data.paymentUrl != null &&
            data.paymentUrl!.isNotEmpty &&
            data.txnRef != null) {
          emit(
            VnpayUrlReady(
              paymentUrl: data.paymentUrl!,
              txnRef: data.txnRef!,
              totalAmount: data.totalAmount,
            ),
          );
        } else {
          emit(
            PaymentError(message: AppStrings.current.errorNoPaymentUrl),
          );
        }
      case Failure<OrderResultModel>(:final message):
        emit(PaymentError(message: message));
    }
  }

  /// Bước 2: Verify kết quả sau khi WebView đóng.
  ///
  /// [txnRef] là session ID được nhúng trong URL return. [gateway] chọn đúng
  /// endpoint verify tương ứng cổng đã dùng để tạo giao dịch.
  /// Phát [PaymentLoading] → [PaymentSuccess] hoặc [PaymentFailed].
  Future<void> verifyAfterWebView({
    required String txnRef,
    String gateway = 'sepay',
  }) async {
    emit(const PaymentLoading());

    final result = await _repository.verifyPayment(
      txnRef: txnRef,
      gateway: gateway,
    );

    switch (result) {
      case Success<PaymentVerifyResult>(:final data):
        if (data.isPaid) {
          emit(PaymentSuccess(result: data));
        } else {
          emit(
            PaymentFailed(
              reason: data.isFailed
                  ? AppStrings.current.paymentFailedWithCode(
                      (gateway == 'vnpay'
                              ? data.vnpResponseCode
                              : data.sepayStatus) ??
                          '?',
                    )
                  : AppStrings.current.paymentProcessing,
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
