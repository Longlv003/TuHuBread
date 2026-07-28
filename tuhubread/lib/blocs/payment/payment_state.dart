import 'package:equatable/equatable.dart';

import '../../models/order_result.model.dart';
import '../../models/payment_verify_result.model.dart';

abstract class PaymentState extends Equatable {
  const PaymentState();

  @override
  List<Object?> get props => [];
}

/// Trạng thái khởi tạo
class PaymentInitial extends PaymentState {
  const PaymentInitial();
}

/// Đang tạo URL thanh toán / đang verify
class PaymentLoading extends PaymentState {
  const PaymentLoading();
}

/// Đã nhận được URL thanh toán → sẵn sàng mở WebView
class PaymentUrlReady extends PaymentState {
  final String paymentUrl;
  final double totalAmount;

  const PaymentUrlReady({required this.paymentUrl, required this.totalAmount});

  @override
  List<Object?> get props => [paymentUrl, totalAmount];
}

/// Thanh toán thành công (sau khi verify)
class PaymentSuccess extends PaymentState {
  final PaymentVerifyResult result;

  const PaymentSuccess({required this.result});

  @override
  List<Object?> get props => [result];
}

/// Thanh toán thất bại hoặc bị hủy (sau khi verify)
class PaymentFailed extends PaymentState {
  final String reason;

  const PaymentFailed({required this.reason});

  @override
  List<Object?> get props => [reason];
}

/// Lỗi xảy ra
class PaymentError extends PaymentState {
  final String message;

  const PaymentError({required this.message});

  @override
  List<Object?> get props => [message];
}
