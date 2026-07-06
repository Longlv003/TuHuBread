// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductModel _$ProductModelFromJson(Map<String, dynamic> json) => ProductModel(
  id: json['_id'] as String,
  shopId: json['shop_id'] as String,
  categoryId: json['category_id'] as String,
  shopCategoryId: json['shop_category_id'] as String?,
  productName: json['product_name'] as String,
  productSlug: json['product_slug'] as String,
  price: (json['price'] as num).toDouble(),
  image: json['image'] as String,
  description: json['description'] as String,
  rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
  salesCount: (json['sales_count'] as num?)?.toInt() ?? 0,
  status: json['status'] as String,
);

Map<String, dynamic> _$ProductModelToJson(ProductModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'shop_id': instance.shopId,
      'category_id': instance.categoryId,
      'shop_category_id': instance.shopCategoryId,
      'product_name': instance.productName,
      'product_slug': instance.productSlug,
      'price': instance.price,
      'image': instance.image,
      'description': instance.description,
      'rating': instance.rating,
      'sales_count': instance.salesCount,
      'status': instance.status,
    };
