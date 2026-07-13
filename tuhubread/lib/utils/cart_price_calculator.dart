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

    final activeSale = detail.activeSale;
    if (activeSale != null && activeSale.isActiveNow) {
      if (activeSale.variantId == null || activeSale.variantId == variant.id) {
        basePrice = activeSale.salePrice;
      }
    } else if (variant.salePrice != null) {
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
