// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shop_category.model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShopCategoryModel _$ShopCategoryModelFromJson(Map<String, dynamic> json) =>
    ShopCategoryModel(
      id: json['_id'] as String,
      shopId: json['shop_id'] as String,
      categoryName: json['category_name'] as String,
      categorySlug: json['category_slug'] as String,
      categoryIcon: json['category_icon'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      status: json['status'] as String,
    );

Map<String, dynamic> _$ShopCategoryModelToJson(ShopCategoryModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'shop_id': instance.shopId,
      'category_name': instance.categoryName,
      'category_slug': instance.categorySlug,
      'category_icon': instance.categoryIcon,
      'sort_order': instance.sortOrder,
      'status': instance.status,
    };
