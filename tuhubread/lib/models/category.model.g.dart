// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category.model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CategoryModel _$CategoryModelFromJson(Map<String, dynamic> json) =>
    CategoryModel(
      id: json['_id'] as String,
      categoryName: json['category_name'] as String,
      categorySlug: json['category_slug'] as String,
      categoryIcon: json['category_icon'] as String,
      status: json['status'] as String,
    );

Map<String, dynamic> _$CategoryModelToJson(CategoryModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'category_name': instance.categoryName,
      'category_slug': instance.categorySlug,
      'category_icon': instance.categoryIcon,
      'status': instance.status,
    };
