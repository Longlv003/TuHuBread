import 'package:equatable/equatable.dart';
import '../../models/cart_item.model.dart';

class CartState extends Equatable {
  final List<CartItemModel> items;

  /// ID các cart item đang có request tăng/giảm/xoá số lượng bay ra server —
  /// dùng để chặn double-tap gây mất đồng bộ số lượng (xem CartCubit).
  final Set<String> pendingItemIds;

  const CartState({this.items = const [], this.pendingItemIds = const {}});

  bool get isEmpty => items.isEmpty;

  int get totalQuantity =>
      items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal =>
      items.fold(0.0, (sum, item) => sum + item.lineTotal);

  bool isPending(String itemId) => pendingItemIds.contains(itemId);

  CartState copyWith({List<CartItemModel>? items, Set<String>? pendingItemIds}) {
    return CartState(
      items: items ?? this.items,
      pendingItemIds: pendingItemIds ?? this.pendingItemIds,
    );
  }

  @override
  List<Object?> get props => [items, pendingItemIds];
}
