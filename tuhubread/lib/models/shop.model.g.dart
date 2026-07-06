// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shop.model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShopModel _$ShopModelFromJson(Map<String, dynamic> json) => ShopModel(
  id: json['_id'] as String,
  shopName: json['shop_name'] as String,
  phone: json['phone'] as String,
  avatar: json['avatar'] as String,
  banner: json['banner'] as String,
  rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
  status: json['status'] as String,
);

Map<String, dynamic> _$ShopModelToJson(ShopModel instance) => <String, dynamic>{
  '_id': instance.id,
  'shop_name': instance.shopName,
  'phone': instance.phone,
  'avatar': instance.avatar,
  'banner': instance.banner,
  'rating': instance.rating,
  'status': instance.status,
};
