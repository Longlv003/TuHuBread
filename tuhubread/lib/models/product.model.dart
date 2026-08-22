import 'package:json_annotation/json_annotation.dart';

part 'product.model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ProductModel {
  @JsonKey(name: '_id')
  final String id;
  final String shopId;
  @JsonKey(name: 'global_category_id')
  final String categoryId;
  final String productName;
  final String productSlug;
  final double price; // Giá gốc của sản phẩm (lấy từ variant mặc định)
  final double? salePrice; // Giá khuyến mãi của variant mặc định (nếu có)
  final String image;
  final String? description;
  @JsonKey(defaultValue: 5.0)
  final double rating;
  @JsonKey(defaultValue: 0)
  final int salesCount;
  @JsonKey(defaultValue: false)
  final bool isFeatured;
  final String status;

  bool get hasDiscount => salePrice != null && salePrice! < price;

  /// Giá thực tế hiển thị cho khách (đã áp khuyến mãi nếu có).
  double get displayPrice => hasDiscount ? salePrice! : price;

  /// Phần trăm giảm giá đã làm tròn, dùng cho nhãn "-20%".
  int get discountPercent =>
      hasDiscount && price > 0 ? (((price - salePrice!) / price) * 100).round() : 0;

  ProductModel({
    required this.id,
    required this.shopId,
    required this.categoryId,
    required this.productName,
    required this.productSlug,
    required this.price,
    this.salePrice,
    required this.image,
    this.description,
    required this.rating,
    required this.salesCount,
    this.isFeatured = false,
    required this.status,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductModelToJson(this);
}
