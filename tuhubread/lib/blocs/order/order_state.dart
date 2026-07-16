import 'package:equatable/equatable.dart';
import '../../models/order.model.dart';
import '../../models/order_item.model.dart';

abstract class OrderState extends Equatable {
  const OrderState();

  @override
  List<Object?> get props => [];
}

class OrderInitial extends OrderState {
  const OrderInitial();
}

class OrderLoading extends OrderState {
  const OrderLoading();
}

class OrderFailure extends OrderState {
  final String error;

  const OrderFailure(this.error);

  @override
  List<Object?> get props => [error];
}

class OrderLoaded extends OrderState {
  final List<OrderModel> orders;

  const OrderLoaded(this.orders);

  @override
  List<Object?> get props => [orders];
}

class OrderDetailLoaded extends OrderState {
  final OrderModel order;
  final List<OrderItemModel> items;
  final bool isCancelling;

  const OrderDetailLoaded({
    required this.order,
    required this.items,
    this.isCancelling = false,
  });

  OrderDetailLoaded copyWith({
    OrderModel? order,
    List<OrderItemModel>? items,
    bool? isCancelling,
  }) {
    return OrderDetailLoaded(
      order: order ?? this.order,
      items: items ?? this.items,
      isCancelling: isCancelling ?? this.isCancelling,
    );
  }

  @override
  List<Object?> get props => [order, items, isCancelling];
}
