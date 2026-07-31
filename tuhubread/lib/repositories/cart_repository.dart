import '../core/result.dart';
import '../models/cart_item.model.dart';
import '../models/shop.model.dart';

abstract class CartRepository {
  Future<Result<List<CartItemModel>>> getCart();

  /// Thêm sản phẩm vào giỏ. Nếu giỏ đang có sản phẩm của chi nhánh khác,
  /// backend từ chối (trừ khi [replaceCart] = true — dùng khi người dùng đã
  /// xác nhận muốn xoá giỏ cũ để đặt hàng từ chi nhánh mới).
  Future<Result<List<CartItemModel>>> addToCart({
    required String productId,
    required String variantId,
    required List<String> optionIds,
    required int quantity,
    String? note,
    bool replaceCart = false,
  });

  /// Xoá toàn bộ giỏ hàng trên server.
  Future<Result<List<CartItemModel>>> clearCart();
  Future<Result<List<CartItemModel>>> updateCartItem({
    required String itemId,
    required int quantity,
    String? note,
  });
  Future<Result<List<CartItemModel>>> deleteCartItem(String itemId);

  Future<Result<List<ShopModel>>> getSwitchShopOptions({
    required String productId,
  });

  Future<Result<List<CartItemModel>>> switchShop({
    required String shopId,
    required String productId,
    required String variantId,
    required List<String> optionIds,
    required int quantity,
  });
}
