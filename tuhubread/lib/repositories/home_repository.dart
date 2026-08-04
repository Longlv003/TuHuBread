import '../core/result.dart';
import '../models/category.model.dart';
import '../models/product.model.dart';
import '../models/product_detail.model.dart';
import '../models/shop.model.dart';
import '../models/voucher.model.dart';

/// Abstract interface — Cubit chỉ phụ thuộc vào interface này,
/// không biết gì về ApiService hay Dio bên dưới.
abstract class HomeRepository {
  /// [lat]/[lng] tuỳ chọn — nếu có, backend trả kèm khoảng cách và sắp xếp
  /// cửa hàng gần vị trí đó lên đầu (dùng để tìm shop gần khách hàng).
  Future<Result<List<ShopModel>>> fetchShops({double? lat, double? lng});
  Future<Result<List<CategoryModel>>> fetchCategories();
  Future<Result<List<ProductModel>>> fetchProducts();
  Future<Result<List<ProductModel>>> fetchBestSellers();
  Future<Result<List<VoucherModel>>> fetchActiveVouchers();
  Future<Result<bool>> saveVoucher(String voucherId);
  Future<Result<ProductDetailModel>> fetchProductDetail(String id);
}
