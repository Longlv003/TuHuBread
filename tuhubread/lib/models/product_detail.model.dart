import 'package:json_annotation/json_annotation.dart';
import 'product_variant.model.dart';
import 'product_option.model.dart';
import 'product_attribute.model.dart';
import 'product_sale.model.dart';

import 'product_review.model.dart';

part 'product_detail.model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ProductDetailShopModel {
  @JsonKey(name: '_id')
  final String id;
  final String shopName;
  final String address;
  final String phoneNumber;
  final String? logo;

  ProductDetailShopModel({
    required this.id,
    required this.shopName,
    required this.address,
    required this.phoneNumber,
    this.logo,
  });

  factory ProductDetailShopModel.fromJson(Map<String, dynamic> json) =>
      _$ProductDetailShopModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductDetailShopModelToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class ProductDetailModel {
  @JsonKey(name: '_id')
  final String id;
  final String shopId;
  @JsonKey(name: 'global_category_id')
  final String categoryId;
  @JsonKey(name: 'shop_category_id')
  final String? shopCategoryId;
  final String productName;
  final String productSlug;
  final String description;
  final int preparationTimeMinutes;
  final String status;
  @JsonKey(defaultValue: 0.0)
  final double rating;
  @JsonKey(defaultValue: 0)
  final int salesCount;
  final double price;
  final String image;
  final ProductDetailShopModel? shop;
  @JsonKey(defaultValue: 0)
  final int? totalReviews;
  final List<ProductReviewModel>? reviews;
  final List<ProductVariantModel> variants;
  final List<ProductOptionModel> options;
  final List<ProductAttributeModel> attributes;
  final ProductSaleModel? activeSale;
  @JsonKey(defaultValue: [])
  final List<ProductDetailOtherShopModel> otherShops;

  ProductDetailModel({
    required this.id,
    required this.shopId,
    required this.categoryId,
    this.shopCategoryId,
    required this.productName,
    required this.productSlug,
    required this.description,
    required this.preparationTimeMinutes,
    required this.status,
    required this.rating,
    required this.salesCount,
    required this.price,
    required this.image,
    this.shop,
    this.totalReviews,
    this.reviews,
    required this.variants,
    required this.options,
    required this.attributes,
    this.activeSale,
    required this.otherShops,
  });

  factory ProductDetailModel.fromJson(Map<String, dynamic> json) =>
      _$ProductDetailModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductDetailModelToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class ProductDetailOtherShopModel {
  @JsonKey(name: 'product_id')
  final String productId;
  final String shopId;
  final String shopName;
  final double price;
  final double? salePrice;

  ProductDetailOtherShopModel({
    required this.productId,
    required this.shopId,
    required this.shopName,
    required this.price,
    this.salePrice,
  });

  factory ProductDetailOtherShopModel.fromJson(Map<String, dynamic> json) =>
      _$ProductDetailOtherShopModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductDetailOtherShopModelToJson(this);
}
