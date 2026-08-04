// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shop.model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShopModel _$ShopModelFromJson(Map<String, dynamic> json) => ShopModel(
  id: json['_id'] as String,
  shopName: json['shop_name'] as String,
  phone: json['phone_number'] as String,
  logo: json['logo'] as String,
  banner: json['banner'] as String,
  rating: (json['rating_average'] as num?)?.toDouble(),
  status: json['status'] as String,
  address: json['address'] as String,
  distanceKm: (json['distance_km'] as num?)?.toDouble(),
);

Map<String, dynamic> _$ShopModelToJson(ShopModel instance) => <String, dynamic>{
  '_id': instance.id,
  'shop_name': instance.shopName,
  'phone_number': instance.phone,
  'logo': instance.logo,
  'banner': instance.banner,
  'rating_average': instance.rating,
  'status': instance.status,
  'address': instance.address,
  'distance_km': instance.distanceKm,
};
