import '../core/result.dart';
import '../models/cart_item.model.dart';

abstract class CartRepository {
  Future<Result<List<CartItemModel>>> getCart();
  Future<Result<List<CartItemModel>>> addToCart({
    required String productId,
    required String variantId,
    required List<String> optionIds,
    required int quantity,
    String? note,
  });
  Future<Result<List<CartItemModel>>> updateCartItem({
    required String itemId,
    required int quantity,
    String? note,
  });
  Future<Result<List<CartItemModel>>> deleteCartItem(String itemId);
}
