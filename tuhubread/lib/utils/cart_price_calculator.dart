import '../models/product_detail.model.dart';
import '../models/product_variant.model.dart';

/// Tính giá đơn vị cho một cấu hình sản phẩm (variant + options).
class CartPriceCalculator {
  CartPriceCalculator._();

  static double calculateUnitPrice(
    ProductDetailModel detail,
    ProductVariantModel variant,
    Set<String> optionIds,
  ) {
    double basePrice = variant.price;

    if (variant.salePrice != null) {
      basePrice = variant.salePrice!;
    }

    double optionTotal = 0;
    for (final opt in detail.options) {
      if (optionIds.contains(opt.id)) {
        optionTotal += opt.extraPrice;
      }
    }

    return basePrice + optionTotal;
  }
}
