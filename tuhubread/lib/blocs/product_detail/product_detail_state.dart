import 'package:equatable/equatable.dart';
import '../../models/product_detail.model.dart';
import '../../models/product_variant.model.dart';

abstract class ProductDetailState extends Equatable {
  const ProductDetailState();

  @override
  List<Object?> get props => [];
}

class ProductDetailInitial extends ProductDetailState {
  const ProductDetailInitial();
}

class ProductDetailLoading extends ProductDetailState {
  const ProductDetailLoading();
}

class ProductDetailFailure extends ProductDetailState {
  final String error;

  const ProductDetailFailure(this.error);

  @override
  List<Object?> get props => [error];
}

class ProductDetailLoaded extends ProductDetailState {
  final ProductDetailModel productDetail;
  final ProductVariantModel selectedVariant;
  final Set<String> selectedOptionIds;
  final int quantity;
  final double totalPrice;

  const ProductDetailLoaded({
    required this.productDetail,
    required this.selectedVariant,
    required this.selectedOptionIds,
    this.quantity = 1,
    required this.totalPrice,
  });

  ProductDetailLoaded copyWith({
    ProductDetailModel? productDetail,
    ProductVariantModel? selectedVariant,
    Set<String>? selectedOptionIds,
    int? quantity,
    double? totalPrice,
  }) {
    return ProductDetailLoaded(
      productDetail: productDetail ?? this.productDetail,
      selectedVariant: selectedVariant ?? this.selectedVariant,
      selectedOptionIds: selectedOptionIds ?? this.selectedOptionIds,
      quantity: quantity ?? this.quantity,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }

  @override
  List<Object?> get props => [
        productDetail,
        selectedVariant,
        selectedOptionIds,
        quantity,
        totalPrice,
      ];
}
