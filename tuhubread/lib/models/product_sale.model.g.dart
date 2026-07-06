// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_sale.model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductSaleModel _$ProductSaleModelFromJson(Map<String, dynamic> json) =>
    ProductSaleModel(
      id: json['_id'] as String,
      productId: json['product_id'] as String,
      variantId: json['variant_id'] as String?,
      saleName: json['sale_name'] as String,
      salePrice: (json['sale_price'] as num).toDouble(),
      saleLimit: (json['sale_limit'] as num?)?.toInt(),
      soldQuantity: (json['sold_quantity'] as num).toInt(),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      status: json['status'] as String,
    );

Map<String, dynamic> _$ProductSaleModelToJson(ProductSaleModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'product_id': instance.productId,
      'variant_id': instance.variantId,
      'sale_name': instance.saleName,
      'sale_price': instance.salePrice,
      'sale_limit': instance.saleLimit,
      'sold_quantity': instance.soldQuantity,
      'start_date': instance.startDate.toIso8601String(),
      'end_date': instance.endDate.toIso8601String(),
      'status': instance.status,
    };
