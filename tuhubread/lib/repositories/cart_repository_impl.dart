import 'package:logger/logger.dart';

import '../core/result.dart';
import '../models/cart_item.model.dart';
import '../services/api_service.dart';
import 'cart_repository.dart';
import '../l10n/app_strings.dart';

final _log = Logger(
  printer: PrettyPrinter(methodCount: 1, colors: true, printEmojis: true),
);

class CartRepositoryImpl implements CartRepository {
  final ApiService apiService;

  const CartRepositoryImpl({required this.apiService});

  List<CartItemModel> _parseCartItems(Map<String, dynamic> json) {
    final list = (json['items'] as List? ?? []);
    return list
        .map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Result<List<CartItemModel>>> getCart() async {
    try {
      final res = await apiService.get('/api/carts');
      if (res['data'] != null) {
        return Success(_parseCartItems(res['data'] as Map<String, dynamic>));
      }
      return Failure(res['msg'] ?? AppStrings.current.errorLoadCart);
    } catch (e, s) {
      _log.e('[getCart] Failed', error: e, stackTrace: s);
      return Failure(AppStrings.current.errorConnectLoadCart);
    }
  }

  @override
  Future<Result<List<CartItemModel>>> addToCart({
    required String productId,
    required String variantId,
    required List<String> optionIds,
    required int quantity,
    String? note,
    bool replaceCart = false,
  }) async {
    try {
      final res = await apiService.post('/api/carts/items', {
        'product_id': productId,
        'variant_id': variantId,
        'selected_options': optionIds.map((id) => {'option_id': id}).toList(),
        'quantity': quantity,
        'note': note,
        if (replaceCart) 'replace_cart': true,
      });
      if (res['data'] != null) {
        return Success(_parseCartItems(res['data'] as Map<String, dynamic>));
      }
      return Failure(res['msg'] ?? AppStrings.current.errorAddToCart);
    } catch (e, s) {
      _log.e('[addToCart] Failed', error: e, stackTrace: s);
      return Failure(AppStrings.current.errorConnectAddToCart);
    }
  }

  @override
  Future<Result<List<CartItemModel>>> clearCart() async {
    try {
      final res = await apiService.delete('/api/carts');
      if (res['data'] != null) {
        return Success(_parseCartItems(res['data'] as Map<String, dynamic>));
      }
      return Failure(res['msg'] ?? AppStrings.current.errorClearCart);
    } catch (e, s) {
      _log.e('[clearCart] Failed', error: e, stackTrace: s);
      return Failure(AppStrings.current.errorConnectClearCart);
    }
  }

  @override
  Future<Result<List<CartItemModel>>> updateCartItem({
    required String itemId,
    required int quantity,
    String? note,
  }) async {
    try {
      final res = await apiService.put('/api/carts/items/$itemId', {
        'quantity': quantity,
        'note': note,
      });
      if (res['data'] != null) {
        return Success(_parseCartItems(res['data'] as Map<String, dynamic>));
      }
      return Failure(res['msg'] ?? AppStrings.current.errorUpdateQuantity);
    } catch (e, s) {
      _log.e('[updateCartItem] Failed', error: e, stackTrace: s);
      return Failure(AppStrings.current.errorConnectUpdateQuantity);
    }
  }

  @override
  Future<Result<List<CartItemModel>>> deleteCartItem(String itemId) async {
    try {
      final res = await apiService.delete('/api/carts/items/$itemId');
      if (res['data'] != null) {
        return Success(_parseCartItems(res['data'] as Map<String, dynamic>));
      }
      return Failure(res['msg'] ?? AppStrings.current.errorRemoveFromCart);
    } catch (e, s) {
      _log.e('[deleteCartItem] Failed', error: e, stackTrace: s);
      return Failure(AppStrings.current.errorConnectRemoveFromCart);
    }
  }
}
