import 'package:logger/logger.dart';

import '../core/result.dart';
import '../models/category.model.dart';
import '../models/product.model.dart';
import '../models/product_sale.model.dart';
import '../models/shop.model.dart';
import '../models/voucher.model.dart';
import '../models/product_detail.model.dart';
import '../models/shop_category.model.dart';
import '../services/api_service.dart';
import 'home_repository.dart';

final _log = Logger(
  printer: PrettyPrinter(methodCount: 1, colors: true, printEmojis: true),
);

class HomeRepositoryImpl implements HomeRepository {
  final ApiService apiService;

  const HomeRepositoryImpl({required this.apiService});

  // ─── Helper: parse list an toàn ───────────────────────────────────────────

  /// Parse list từ JSON, trả về list rỗng nếu data null hoặc parse lỗi
  List<T> _parseList<T>(
    dynamic data,
    T Function(Map<String, dynamic>) fromJson,
    String label,
  ) {
    if (data == null) return [];
    try {
      return (data as List)
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, s) {
      _log.w('[$label] Parse error', error: e, stackTrace: s);
      return [];
    }
  }

  // ─── Shops ────────────────────────────────────────────────────────────────

  @override
  Future<Result<List<ShopModel>>> fetchShops() async {
    try {
      final res = await apiService.get('/api/shops');
      final shops = _parseList(res['data'], ShopModel.fromJson, 'fetchShops');
      return Success(shops);
    } catch (e, s) {
      _log.e('[fetchShops] Failed', error: e, stackTrace: s);
      return Failure('Không thể tải danh sách cửa hàng');
    }
  }

  // ─── Categories ──────────────────────────────────────────────────────────

  @override
  Future<Result<List<CategoryModel>>> fetchCategories() async {
    try {
      final res = await apiService.get('/api/categories');
      final cats = _parseList(
        res['data'],
        CategoryModel.fromJson,
        'fetchCategories',
      );
      return Success(cats);
    } catch (e, s) {
      _log.e('[fetchCategories] Failed', error: e, stackTrace: s);
      return Failure('Không thể tải danh mục');
    }
  }

  // ─── All Products ─────────────────────────────────────────────────────────

  @override
  Future<Result<List<ProductModel>>> fetchProducts() async {
    try {
      final res = await apiService.get('/api/products');
      final products = _parseList(
        res['data'],
        ProductModel.fromJson,
        'fetchProducts',
      );
      return Success(products);
    } catch (e, s) {
      _log.e('[fetchProducts] Failed', error: e, stackTrace: s);
      return Failure('Không thể tải thực đơn');
    }
  }

  // ─── Best Sellers ─────────────────────────────────────────────────────────

  @override
  Future<Result<List<ProductModel>>> fetchBestSellers() async {
    try {
      final res = await apiService.get('/api/products/best-sellers');
      final products = _parseList(
        res['data'],
        ProductModel.fromJson,
        'fetchBestSellers',
      );
      return Success(products);
    } catch (e, s) {
      _log.e('[fetchBestSellers] Failed', error: e, stackTrace: s);
      return Failure('Không thể tải sản phẩm bán chạy');
    }
  }

  // ─── Sale Products ────────────────────────────────────────────────────────

  @override
  Future<Result<SaleDataResult>> fetchSaleProducts() async {
    try {
      final res = await apiService.get('/api/products/sales');
      final rawList = res['data'];

      if (rawList == null) {
        return const Success(SaleDataResult(products: [], sales: []));
      }

      final products = <ProductModel>[];
      final sales = <ProductSaleModel>[];

      for (final item in rawList as List) {
        final map = item as Map<String, dynamic>;
        try {
          products.add(ProductModel.fromJson(map));
          if (map['active_sale'] != null) {
            sales.add(
              ProductSaleModel.fromJson(
                map['active_sale'] as Map<String, dynamic>,
              ),
            );
          }
        } catch (e) {
          // Bỏ qua item lỗi, không crash toàn bộ list
          _log.w('[fetchSaleProducts] Skip 1 item parse error: $e');
        }
      }

      return Success(SaleDataResult(products: products, sales: sales));
    } catch (e, s) {
      _log.e('[fetchSaleProducts] Failed', error: e, stackTrace: s);
      return Failure('Không thể tải sản phẩm khuyến mãi');
    }
  }

  // ─── Vouchers ─────────────────────────────────────────────────────────────

  @override
  Future<Result<List<VoucherModel>>> fetchActiveVouchers() async {
    try {
      final res = await apiService.get('/api/vouchers');
      final vouchers = _parseList(
        res['data'],
        VoucherModel.fromJson,
        'fetchActiveVouchers',
      );
      return Success(vouchers);
    } catch (e, s) {
      _log.e('[fetchActiveVouchers] Failed', error: e, stackTrace: s);
      return Failure('Không thể tải voucher');
    }
  }

  @override
  Future<Result<bool>> saveVoucher(String voucherId) async {
    try {
      final res = await apiService.post('/api/vouchers/$voucherId/save', {});
      if (res['data'] != null) {
        return const Success(true);
      }
      return Failure(res['msg'] ?? 'Lưu voucher thất bại');
    } catch (e, s) {
      _log.e('[saveVoucher] Failed', error: e, stackTrace: s);
      return Failure('Không thể kết nối đến máy chủ để lưu voucher');
    }
  }

  @override
  Future<Result<ProductDetailModel>> fetchProductDetail(String id) async {
    try {
      final res = await apiService.get('/api/products/$id');
      if (res['data'] != null) {
        final detail = ProductDetailModel.fromJson(res['data'] as Map<String, dynamic>);
        return Success(detail);
      }
      return Failure(res['msg'] ?? 'Không thể tải chi tiết sản phẩm');
    } catch (e, s) {
      _log.e('[fetchProductDetail] Failed', error: e, stackTrace: s);
      return const Failure('Lỗi kết nối máy chủ');
    }
  }

  @override
  Future<Result<List<ShopCategoryModel>>> fetchShopCategories(String shopId) async {
    try {
      final res = await apiService.get('/api/shops/$shopId/categories');
      final cats = _parseList(
        res['data'],
        ShopCategoryModel.fromJson,
        'fetchShopCategories',
      );
      return Success(cats);
    } catch (e, s) {
      _log.e('[fetchShopCategories] Failed', error: e, stackTrace: s);
      return Failure('Không thể tải danh mục của cửa hàng');
    }
  }
}
