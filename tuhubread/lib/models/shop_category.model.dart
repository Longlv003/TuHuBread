import 'package:json_annotation/json_annotation.dart';

part 'shop_category.model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ShopCategoryModel {
  @JsonKey(name: '_id')
  final String id;
  final String shopId;
  final String categoryName;
  final String categorySlug;
  @JsonKey(defaultValue: null)
  final String? categoryIcon;
  @JsonKey(defaultValue: 0)
  final int sortOrder;
  final String status;

  ShopCategoryModel({
    required this.id,
    required this.shopId,
    required this.categoryName,
    required this.categorySlug,
    this.categoryIcon,
    required this.sortOrder,
    required this.status,
  });

  factory ShopCategoryModel.fromJson(Map<String, dynamic> json) =>
      _$ShopCategoryModelFromJson(json);

  Map<String, dynamic> toJson() => _$ShopCategoryModelToJson(this);
}
