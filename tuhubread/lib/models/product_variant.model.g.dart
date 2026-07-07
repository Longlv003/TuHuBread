// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_variant.model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductVariantModel _$ProductVariantModelFromJson(Map<String, dynamic> json) =>
    ProductVariantModel(
      id: json['_id'] as String,
      productId: json['product_id'] as String,
      variantName: json['variant_name'] as String,
      variantSlug: json['variant_slug'] as String,
      image: json['image'] as String?,
      price: (json['price'] as num).toDouble(),
      salePrice: (json['sale_price'] as num?)?.toDouble(),
      stockQuantity: (json['stock_quantity'] as num).toInt(),
      soldQuantity: (json['sold_quantity'] as num).toInt(),
      status: json['status'] as String,
    );

Map<String, dynamic> _$ProductVariantModelToJson(
  ProductVariantModel instance,
) => <String, dynamic>{
  '_id': instance.id,
  'product_id': instance.productId,
  'variant_name': instance.variantName,
  'variant_slug': instance.variantSlug,
  'image': instance.image,
  'price': instance.price,
  'sale_price': instance.salePrice,
  'stock_quantity': instance.stockQuantity,
  'sold_quantity': instance.soldQuantity,
  'status': instance.status,
};
