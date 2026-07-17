import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/product_detail/product_detail_state.dart';
import '../../models/cart_item.model.dart';
import '../../utils/cart_price_calculator.dart';
import 'cart_state.dart';

class CartCubit extends Cubit<CartState> {
  CartCubit() : super(const CartState());

  /// Thêm sản phẩm từ màn chi tiết. Nếu cấu hình trùng khớp hoàn toàn thì cộng dồn số lượng.
  void addFromProductDetail(ProductDetailLoaded detailState) {
    final detail = detailState.productDetail;
    final variant = detailState.selectedVariant;
    final optionIds = detailState.selectedOptionIds;
    final configKey = CartItemModel.buildConfigKey(
      detail.id,
      variant.id,
      optionIds,
    );

    final existingIndex =
        state.items.indexWhere((item) => item.id == configKey);

    if (existingIndex >= 0) {
      final updatedItems = List<CartItemModel>.from(state.items);
      final existing = updatedItems[existingIndex];
      updatedItems[existingIndex] = existing.copyWith(
        quantity: existing.quantity + detailState.quantity,
      );
      emit(state.copyWith(items: updatedItems));
      return;
    }

    final unitPrice = CartPriceCalculator.calculateUnitPrice(
      detail,
      variant,
      optionIds,
    );

    final optionNames = detail.options
        .where((opt) => optionIds.contains(opt.id))
        .map((opt) => opt.optionName)
        .toList();

    final newItem = CartItemModel(
      id: configKey,
      productId: detail.id,
      productName: detail.productName,
      image: detail.image,
      shopId: detail.shopId,
      shopName: detail.shop?.shopName,
      variantId: variant.id,
      variantName: variant.variantName,
      selectedOptionIds: Set<String>.from(optionIds),
      selectedOptionNames: optionNames,
      quantity: detailState.quantity,
      unitPrice: unitPrice,
    );

    emit(state.copyWith(items: [...state.items, newItem]));
  }

  void incrementQuantity(String itemId) {
    final index = state.items.indexWhere((item) => item.id == itemId);
    if (index < 0) return;

    final updatedItems = List<CartItemModel>.from(state.items);
    final item = updatedItems[index];
    updatedItems[index] = item.copyWith(quantity: item.quantity + 1);
    emit(state.copyWith(items: updatedItems));
  }

  void decrementQuantity(String itemId) {
    final index = state.items.indexWhere((item) => item.id == itemId);
    if (index < 0) return;

    final item = state.items[index];
    if (item.quantity <= 1) {
      removeItem(itemId);
      return;
    }

    final updatedItems = List<CartItemModel>.from(state.items);
    updatedItems[index] = item.copyWith(quantity: item.quantity - 1);
    emit(state.copyWith(items: updatedItems));
  }

  void removeItem(String itemId) {
    final updatedItems =
        state.items.where((item) => item.id != itemId).toList();
    emit(state.copyWith(items: updatedItems));
  }

  void clearCart() {
    emit(const CartState());
  }
}
