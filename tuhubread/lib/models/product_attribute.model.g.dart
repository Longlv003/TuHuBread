// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_attribute.model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductAttributeModel _$ProductAttributeModelFromJson(
  Map<String, dynamic> json,
) => ProductAttributeModel(
  id: json['_id'] as String,
  productId: json['product_id'] as String,
  attributeKey: json['attribute_key'] as String,
  attributeLabel: json['attribute_label'] as String,
  attributeValue: json['attribute_value'] as String,
  sortOrder: (json['sort_order'] as num).toInt(),
  status: json['status'] as String,
);

Map<String, dynamic> _$ProductAttributeModelToJson(
  ProductAttributeModel instance,
) => <String, dynamic>{
  '_id': instance.id,
  'product_id': instance.productId,
  'attribute_key': instance.attributeKey,
  'attribute_label': instance.attributeLabel,
  'attribute_value': instance.attributeValue,
  'sort_order': instance.sortOrder,
  'status': instance.status,
};
