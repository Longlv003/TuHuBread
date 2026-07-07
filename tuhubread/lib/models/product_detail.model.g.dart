// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_detail.model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductDetailShopModel _$ProductDetailShopModelFromJson(
  Map<String, dynamic> json,
) => ProductDetailShopModel(
  id: json['_id'] as String,
  shopName: json['shop_name'] as String,
  address: json['address'] as String,
  phoneNumber: json['phone_number'] as String,
  logo: json['logo'] as String?,
);

Map<String, dynamic> _$ProductDetailShopModelToJson(
  ProductDetailShopModel instance,
) => <String, dynamic>{
  '_id': instance.id,
  'shop_name': instance.shopName,
  'address': instance.address,
  'phone_number': instance.phoneNumber,
  'logo': instance.logo,
};

ProductDetailModel _$ProductDetailModelFromJson(
  Map<String, dynamic> json,
) => ProductDetailModel(
  id: json['_id'] as String,
  shopId: json['shop_id'] as String,
  categoryId: json['global_category_id'] as String,
  shopCategoryId: json['shop_category_id'] as String?,
  productName: json['product_name'] as String,
  productSlug: json['product_slug'] as String,
  description: json['description'] as String,
  preparationTimeMinutes: (json['preparation_time_minutes'] as num).toInt(),
  status: json['status'] as String,
  rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
  salesCount: (json['sales_count'] as num?)?.toInt() ?? 0,
  price: (json['price'] as num).toDouble(),
  image: json['image'] as String,
  shop: json['shop'] == null
      ? null
      : ProductDetailShopModel.fromJson(json['shop'] as Map<String, dynamic>),
  totalReviews: (json['total_reviews'] as num?)?.toInt() ?? 0,
  reviews: (json['reviews'] as List<dynamic>?)
      ?.map((e) => ProductReviewModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  variants: (json['variants'] as List<dynamic>)
      .map((e) => ProductVariantModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  options: (json['options'] as List<dynamic>)
      .map((e) => ProductOptionModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  attributes: (json['attributes'] as List<dynamic>)
      .map((e) => ProductAttributeModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  activeSale: json['active_sale'] == null
      ? null
      : ProductSaleModel.fromJson(json['active_sale'] as Map<String, dynamic>),
  otherShops:
      (json['other_shops'] as List<dynamic>?)
          ?.map(
            (e) =>
                ProductDetailOtherShopModel.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      [],
);

Map<String, dynamic> _$ProductDetailModelToJson(ProductDetailModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'shop_id': instance.shopId,
      'global_category_id': instance.categoryId,
      'shop_category_id': instance.shopCategoryId,
      'product_name': instance.productName,
      'product_slug': instance.productSlug,
      'description': instance.description,
      'preparation_time_minutes': instance.preparationTimeMinutes,
      'status': instance.status,
      'rating': instance.rating,
      'sales_count': instance.salesCount,
      'price': instance.price,
      'image': instance.image,
      'shop': instance.shop,
      'total_reviews': instance.totalReviews,
      'reviews': instance.reviews,
      'variants': instance.variants,
      'options': instance.options,
      'attributes': instance.attributes,
      'active_sale': instance.activeSale,
      'other_shops': instance.otherShops,
    };

ProductDetailOtherShopModel _$ProductDetailOtherShopModelFromJson(
  Map<String, dynamic> json,
) => ProductDetailOtherShopModel(
  productId: json['product_id'] as String,
  shopId: json['shop_id'] as String,
  shopName: json['shop_name'] as String,
  price: (json['price'] as num).toDouble(),
  salePrice: (json['sale_price'] as num?)?.toDouble(),
);

Map<String, dynamic> _$ProductDetailOtherShopModelToJson(
  ProductDetailOtherShopModel instance,
) => <String, dynamic>{
  'product_id': instance.productId,
  'shop_id': instance.shopId,
  'shop_name': instance.shopName,
  'price': instance.price,
  'sale_price': instance.salePrice,
};
