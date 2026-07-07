// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_option.model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductOptionModel _$ProductOptionModelFromJson(Map<String, dynamic> json) =>
    ProductOptionModel(
      id: json['_id'] as String,
      productId: json['product_id'] as String,
      optionName: json['option_name'] as String,
      optionSlug: json['option_slug'] as String,
      extraPrice: (json['extra_price'] as num).toDouble(),
      status: json['status'] as String,
    );

Map<String, dynamic> _$ProductOptionModelToJson(ProductOptionModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'product_id': instance.productId,
      'option_name': instance.optionName,
      'option_slug': instance.optionSlug,
      'extra_price': instance.extraPrice,
      'status': instance.status,
    };
