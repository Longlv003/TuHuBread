import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/product_detail/product_detail_state.dart';
import '../../models/cart_item.model.dart';
import '../../repositories/cart_repository.dart';
import '../../core/result.dart';
import 'cart_state.dart';

class CartCubit extends Cubit<CartState> {
  final CartRepository cartRepository;

  CartCubit({required this.cartRepository}) : super(const CartState());

  /// Tải giỏ hàng từ máy chủ khi mở app hoặc login.
  Future<void> loadCart() async {
    final result = await cartRepository.getCart();
    if (result is Success<List<CartItemModel>>) {
      emit(state.copyWith(items: result.data));
    }
  }

  /// Thêm sản phẩm từ màn chi tiết và đồng bộ lên database.
  /// [replaceCart]: true khi người dùng đã xác nhận xoá giỏ hàng cũ (khác
  /// chi nhánh) để đặt hàng từ chi nhánh mới — xem [CartActionHelper].
  Future<Result<List<CartItemModel>>> addFromProductDetail(
    ProductDetailLoaded detailState, {
    bool replaceCart = false,
  }) async {
    final detail = detailState.productDetail;
    final variant = detailState.selectedVariant;
    final optionIds = detailState.selectedOptionIds;

    final result = await cartRepository.addToCart(
      productId: detail.id,
      variantId: variant.id,
      optionIds: optionIds.toList(),
      quantity: detailState.quantity,
      replaceCart: replaceCart,
    );

    if (result is Success<List<CartItemModel>>) {
      emit(state.copyWith(items: result.data));
    }
    return result;
  }

  /// Xoá giỏ hàng thật trên server (khác [clearCart] chỉ reset state cục bộ
  /// dùng sau khi đặt hàng thành công / đăng xuất).
  Future<bool> requestClearCart() async {
    final result = await cartRepository.clearCart();
    if (result is Success<List<CartItemModel>>) {
      emit(state.copyWith(items: result.data));
      return true;
    }
    return false;
  }

  void _setPending(String itemId, bool pending) {
    final next = Set<String>.from(state.pendingItemIds);
    if (pending) {
      next.add(itemId);
    } else {
      next.remove(itemId);
    }
    emit(state.copyWith(pendingItemIds: next));
  }

  Future<void> incrementQuantity(String itemId) async {
    // Chặn double-tap: nếu item đang có request bay đi, bỏ qua tap tiếp theo
    // thay vì đọc lại quantity cũ (đang stale) và gửi nhầm request trùng.
    if (state.isPending(itemId)) return;
    final index = state.items.indexWhere((item) => item.id == itemId);
    if (index < 0) return;

    final item = state.items[index];
    _setPending(itemId, true);
    try {
      final result = await cartRepository.updateCartItem(
        itemId: itemId,
        quantity: item.quantity + 1,
      );

      if (result is Success<List<CartItemModel>>) {
        emit(state.copyWith(items: result.data));
      }
    } finally {
      _setPending(itemId, false);
    }
  }

  Future<void> decrementQuantity(String itemId, {Future<bool> Function()? confirmShow}) async {
    if (state.isPending(itemId)) return;
    final index = state.items.indexWhere((item) => item.id == itemId);
    if (index < 0) return;

    final item = state.items[index];
    if (item.quantity <= 1) {
      if (confirmShow != null) {
        final ok = await confirmShow();
        if (!ok) return;
      }
      await removeItem(itemId);
      return;
    }

    _setPending(itemId, true);
    try {
      final result = await cartRepository.updateCartItem(
        itemId: itemId,
        quantity: item.quantity - 1,
      );

      if (result is Success<List<CartItemModel>>) {
        emit(state.copyWith(items: result.data));
      }
    } finally {
      _setPending(itemId, false);
    }
  }

  Future<void> removeItem(String itemId, {Future<bool> Function()? confirmShow}) async {
    if (state.isPending(itemId)) return;
    if (confirmShow != null) {
      final ok = await confirmShow();
      if (!ok) return;
    }
    _setPending(itemId, true);
    try {
      final result = await cartRepository.deleteCartItem(itemId);
      if (result is Success<List<CartItemModel>>) {
        emit(state.copyWith(items: result.data));
      }
    } finally {
      _setPending(itemId, false);
    }
  }

  void clearCart() {
    emit(const CartState());
  }
}
