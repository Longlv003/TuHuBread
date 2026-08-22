// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductModel _$ProductModelFromJson(Map<String, dynamic> json) => ProductModel(
  id: json['_id'] as String,
  shopId: json['shop_id'] as String,
  categoryId: json['global_category_id'] as String,
  productName: json['product_name'] as String,
  productSlug: json['product_slug'] as String,
  price: (json['price'] as num).toDouble(),
  salePrice: (json['sale_price'] as num?)?.toDouble(),
  image: json['image'] as String,
  description: json['description'] as String?,
  rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
  salesCount: (json['sales_count'] as num?)?.toInt() ?? 0,
  isFeatured: json['is_featured'] as bool? ?? false,
  status: json['status'] as String,
);

Map<String, dynamic> _$ProductModelToJson(ProductModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'shop_id': instance.shopId,
      'global_category_id': instance.categoryId,
      'product_name': instance.productName,
      'product_slug': instance.productSlug,
      'price': instance.price,
      'sale_price': instance.salePrice,
      'image': instance.image,
      'description': instance.description,
      'rating': instance.rating,
      'sales_count': instance.salesCount,
      'is_featured': instance.isFeatured,
      'status': instance.status,
    };
