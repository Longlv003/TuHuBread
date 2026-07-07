import 'package:json_annotation/json_annotation.dart';

part 'product_variant.model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ProductVariantModel {
  @JsonKey(name: '_id')
  final String id;
  final String productId;
  final String variantName;
  final String variantSlug;
  final String? image;
  final double price;
  final double? salePrice;
  final int stockQuantity;
  final int soldQuantity;
  final String status;

  ProductVariantModel({
    required this.id,
    required this.productId,
    required this.variantName,
    required this.variantSlug,
    this.image,
    required this.price,
    this.salePrice,
    required this.stockQuantity,
    required this.soldQuantity,
    required this.status,
  });

  factory ProductVariantModel.fromJson(Map<String, dynamic> json) =>
      _$ProductVariantModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductVariantModelToJson(this);
}
