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
  Future<void> addFromProductDetail(ProductDetailLoaded detailState) async {
    final detail = detailState.productDetail;
    final variant = detailState.selectedVariant;
    final optionIds = detailState.selectedOptionIds;

    final result = await cartRepository.addToCart(
      productId: detail.id,
      variantId: variant.id,
      optionIds: optionIds.toList(),
      quantity: detailState.quantity,
    );

    if (result is Success<List<CartItemModel>>) {
      emit(state.copyWith(items: result.data));
    }
  }

  Future<void> incrementQuantity(String itemId) async {
    final index = state.items.indexWhere((item) => item.id == itemId);
    if (index < 0) return;

    final item = state.items[index];
    final result = await cartRepository.updateCartItem(
      itemId: itemId,
      quantity: item.quantity + 1,
    );

    if (result is Success<List<CartItemModel>>) {
      emit(state.copyWith(items: result.data));
    }
  }

  Future<void> decrementQuantity(String itemId, {Future<bool> Function()? confirmShow}) async {
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

    final result = await cartRepository.updateCartItem(
      itemId: itemId,
      quantity: item.quantity - 1,
    );

    if (result is Success<List<CartItemModel>>) {
      emit(state.copyWith(items: result.data));
    }
  }

  Future<void> removeItem(String itemId, {Future<bool> Function()? confirmShow}) async {
    if (confirmShow != null) {
      final ok = await confirmShow();
      if (!ok) return;
    }
    final result = await cartRepository.deleteCartItem(itemId);
    if (result is Success<List<CartItemModel>>) {
      emit(state.copyWith(items: result.data));
    }
  }

  void clearCart() {
    emit(const CartState());
  }
}
