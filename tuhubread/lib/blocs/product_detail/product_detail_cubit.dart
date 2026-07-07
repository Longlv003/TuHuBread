import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/result.dart';
import '../../models/product_detail.model.dart';
import '../../models/product_variant.model.dart';
import '../../repositories/home_repository.dart';
import 'product_detail_state.dart';

class ProductDetailCubit extends Cubit<ProductDetailState> {
  final HomeRepository repository;

  ProductDetailCubit({required this.repository})
      : super(const ProductDetailInitial());

  Future<void> loadProductDetail(String id) async {
    emit(const ProductDetailLoading());
    final res = await repository.fetchProductDetail(id);

    if (res is Success<ProductDetailModel>) {
      final detail = res.data;
      if (detail.variants.isEmpty) {
        emit(const ProductDetailFailure('Sản phẩm chưa có phiên bản bán ra'));
        return;
      }

      // Chọn variant đầu tiên làm mặc định
      final defaultVariant = detail.variants.first;
      final Set<String> initialOptions = {};
      final initialPrice = _calculatePrice(detail, defaultVariant, initialOptions, 1);

      emit(ProductDetailLoaded(
        productDetail: detail,
        selectedVariant: defaultVariant,
        selectedOptionIds: initialOptions,
        quantity: 1,
        totalPrice: initialPrice,
      ));
    } else {
      emit(ProductDetailFailure(res.errorOrNull ?? 'Lỗi không xác định'));
    }
  }

  void selectVariant(ProductVariantModel variant) {
    if (state is! ProductDetailLoaded) return;
    final current = state as ProductDetailLoaded;

    final newPrice = _calculatePrice(
      current.productDetail,
      variant,
      current.selectedOptionIds,
      current.quantity,
    );

    emit(current.copyWith(
      selectedVariant: variant,
      totalPrice: newPrice,
    ));
  }

  void toggleOption(String optionId) {
    if (state is! ProductDetailLoaded) return;
    final current = state as ProductDetailLoaded;

    final updatedOptions = Set<String>.from(current.selectedOptionIds);
    if (updatedOptions.contains(optionId)) {
      updatedOptions.remove(optionId);
    } else {
      updatedOptions.add(optionId);
    }

    final newPrice = _calculatePrice(
      current.productDetail,
      current.selectedVariant,
      updatedOptions,
      current.quantity,
    );

    emit(current.copyWith(
      selectedOptionIds: updatedOptions,
      totalPrice: newPrice,
    ));
  }

  void incrementQuantity() {
    if (state is! ProductDetailLoaded) return;
    final current = state as ProductDetailLoaded;

    final newQty = current.quantity + 1;
    final newPrice = _calculatePrice(
      current.productDetail,
      current.selectedVariant,
      current.selectedOptionIds,
      newQty,
    );

    emit(current.copyWith(
      quantity: newQty,
      totalPrice: newPrice,
    ));
  }

  void decrementQuantity() {
    if (state is! ProductDetailLoaded) return;
    final current = state as ProductDetailLoaded;

    if (current.quantity <= 1) return;
    final newQty = current.quantity - 1;
    final newPrice = _calculatePrice(
      current.productDetail,
      current.selectedVariant,
      current.selectedOptionIds,
      newQty,
    );

    emit(current.copyWith(
      quantity: newQty,
      totalPrice: newPrice,
    ));
  }

  // ─────────── CALCULATE REALTIME PRICE ───────────

  double _calculatePrice(
    ProductDetailModel detail,
    ProductVariantModel variant,
    Set<String> optionIds,
    int qty,
  ) {
    // 1. Xác định giá gốc của variant
    double basePrice = variant.price;

    // 2. Kiểm tra khuyến mãi sale đang diễn ra
    final activeSale = detail.activeSale;
    if (activeSale != null && activeSale.isActiveNow) {
      if (activeSale.variantId == null || activeSale.variantId == variant.id) {
        basePrice = activeSale.salePrice;
      }
    } else if (variant.salePrice != null) {
      basePrice = variant.salePrice!;
    }

    // 3. Cộng tiền các option chọn thêm
    double optionTotal = 0;
    for (final opt in detail.options) {
      if (optionIds.contains(opt.id)) {
        optionTotal += opt.extraPrice;
      }
    }

    // 4. Nhân với số lượng
    return (basePrice + optionTotal) * qty;
  }
}
