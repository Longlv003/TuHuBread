import '../../models/category.model.dart';
import '../../models/product.model.dart';
import '../../models/product_sale.model.dart';
import '../../models/shop.model.dart';
import '../../models/voucher.model.dart';

abstract class HomeState {
  const HomeState();
}

/// Chưa tải gì — trạng thái khởi tạo
class HomeInitial extends HomeState {
  const HomeInitial();
}

/// Đang tải dữ liệu lần đầu
class HomeLoading extends HomeState {
  const HomeLoading();
}

/// Tải xong — luôn emit state này dù một vài API fail.
/// Các section bị lỗi sẽ có data rỗng và tên section trong [sectionErrors].
class HomeLoaded extends HomeState {
  final List<ShopModel> shops;
  final List<CategoryModel> categories;
  final List<ProductModel> products;
  final List<ProductModel> bestSellers;
  final List<ProductModel> saleProducts;
  final List<ProductSaleModel> productSales;
  final List<VoucherModel> vouchers;

  /// Map<sectionKey, errorMessage> — section nào fail thì có entry ở đây.
  /// UI có thể dùng để hiện banner "Không tải được [section]" thay vì crash.
  final Map<String, String> sectionErrors;

  const HomeLoaded({
    required this.shops,
    required this.categories,
    required this.products,
    required this.bestSellers,
    required this.saleProducts,
    required this.productSales,
    required this.vouchers,
    this.sectionErrors = const {},
  });

  /// Kiểm tra nhanh có section nào lỗi không
  bool get hasPartialError => sectionErrors.isNotEmpty;

  /// copyWith để cập nhật một phần data
  HomeLoaded copyWith({
    List<ShopModel>? shops,
    List<CategoryModel>? categories,
    List<ProductModel>? products,
    List<ProductModel>? bestSellers,
    List<ProductModel>? saleProducts,
    List<ProductSaleModel>? productSales,
    List<VoucherModel>? vouchers,
    Map<String, String>? sectionErrors,
  }) {
    return HomeLoaded(
      shops: shops ?? this.shops,
      categories: categories ?? this.categories,
      products: products ?? this.products,
      bestSellers: bestSellers ?? this.bestSellers,
      saleProducts: saleProducts ?? this.saleProducts,
      productSales: productSales ?? this.productSales,
      vouchers: vouchers ?? this.vouchers,
      sectionErrors: sectionErrors ?? this.sectionErrors,
    );
  }
}

/// Toàn bộ thất bại (không có data nào hết — lỗi mạng hoàn toàn)
class HomeFailure extends HomeState {
  final String error;
  const HomeFailure(this.error);
}
