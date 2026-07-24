import 'package:logger/logger.dart';

import '../core/result.dart';
import '../models/cart_item.model.dart';
import '../services/api_service.dart';
import 'cart_repository.dart';

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
      return Failure(res['msg'] ?? 'Không thể tải giỏ hàng');
    } catch (e, s) {
      _log.e('[getCart] Failed', error: e, stackTrace: s);
      return const Failure('Không thể kết nối đến máy chủ để tải giỏ hàng');
    }
  }

  @override
  Future<Result<List<CartItemModel>>> addToCart({
    required String productId,
    required String variantId,
    required List<String> optionIds,
    required int quantity,
    String? note,
  }) async {
    try {
      final res = await apiService.post('/api/carts/items', {
        'product_id': productId,
        'variant_id': variantId,
        'selected_options': optionIds.map((id) => {'option_id': id}).toList(),
        'quantity': quantity,
        'note': note,
      });
      if (res['data'] != null) {
        return Success(_parseCartItems(res['data'] as Map<String, dynamic>));
      }
      return Failure(res['msg'] ?? 'Không thể thêm vào giỏ hàng');
    } catch (e, s) {
      _log.e('[addToCart] Failed', error: e, stackTrace: s);
      return const Failure('Không thể kết nối đến máy chủ để thêm vào giỏ hàng');
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
      return Failure(res['msg'] ?? 'Không thể cập nhật số lượng');
    } catch (e, s) {
      _log.e('[updateCartItem] Failed', error: e, stackTrace: s);
      return const Failure('Không thể kết nối đến máy chủ để cập nhật số lượng');
    }
  }

  @override
  Future<Result<List<CartItemModel>>> deleteCartItem(String itemId) async {
    try {
      final res = await apiService.delete('/api/carts/items/$itemId');
      if (res['data'] != null) {
        return Success(_parseCartItems(res['data'] as Map<String, dynamic>));
      }
      return Failure(res['msg'] ?? 'Không thể xóa khỏi giỏ hàng');
    } catch (e, s) {
      _log.e('[deleteCartItem] Failed', error: e, stackTrace: s);
      return const Failure('Không thể kết nối đến máy chủ để xóa khỏi giỏ hàng');
    }
  }
}
