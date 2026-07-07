import '../core/result.dart';
import '../models/category.model.dart';
import '../models/product.model.dart';
import '../models/product_sale.model.dart';
import '../models/shop.model.dart';
import '../models/voucher.model.dart';
import '../models/shop_category.model.dart';

import '../models/product_detail.model.dart';

/// Kết quả tổng hợp từ API /products/on-sale
/// (sản phẩm + danh sách thông tin sale tương ứng)
class SaleDataResult {
  final List<ProductModel> products;
  final List<ProductSaleModel> sales;
  const SaleDataResult({required this.products, required this.sales});
}

/// Abstract interface — Cubit chỉ phụ thuộc vào interface này,
/// không biết gì về ApiService hay Dio bên dưới.
abstract class HomeRepository {
  Future<Result<List<ShopModel>>> fetchShops();
  Future<Result<List<CategoryModel>>> fetchCategories();
  Future<Result<List<ProductModel>>> fetchProducts();
  Future<Result<List<ProductModel>>> fetchBestSellers();
  Future<Result<SaleDataResult>> fetchSaleProducts();
  Future<Result<List<VoucherModel>>> fetchActiveVouchers();
  Future<Result<bool>> saveVoucher(String voucherId);
  Future<Result<ProductDetailModel>> fetchProductDetail(String id);
  Future<Result<List<ShopCategoryModel>>> fetchShopCategories(String shopId);
}
