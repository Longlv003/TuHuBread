import 'package:json_annotation/json_annotation.dart';

part 'product.model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ProductModel {
  @JsonKey(name: '_id')
  final String id;
  final String shopId;
  @JsonKey(name: 'global_category_id')
  final String categoryId;
  @JsonKey(name: 'shop_category_id')
  final String? shopCategoryId;
  final String productName;
  final String productSlug;
  final double price; // Giá gốc của sản phẩm (lấy từ variant mặc định)
  final String image;
  final String description;
  @JsonKey(defaultValue: 5.0)
  final double rating;
  @JsonKey(defaultValue: 0)
  final int salesCount;
  final String status;

  ProductModel({
    required this.id,
    required this.shopId,
    required this.categoryId,
    this.shopCategoryId,
    required this.productName,
    required this.productSlug,
    required this.price,
    required this.image,
    required this.description,
    required this.rating,
    required this.salesCount,
    required this.status,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductModelToJson(this);
}
