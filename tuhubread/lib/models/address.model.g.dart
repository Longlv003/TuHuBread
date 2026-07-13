// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'address.model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddressModel _$AddressModelFromJson(Map<String, dynamic> json) => AddressModel(
  id: json['_id'] as String,
  receiverName: json['receiver_name'] as String,
  receiverPhone: json['receiver_phone'] as String,
  addressDetail: json['address_detail'] as String,
  isDefault: json['is_default'] as bool? ?? false,
  label: json['label'] as String? ?? 'other',
);

Map<String, dynamic> _$AddressModelToJson(AddressModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'receiver_name': instance.receiverName,
      'receiver_phone': instance.receiverPhone,
      'address_detail': instance.addressDetail,
      'is_default': instance.isDefault,
      'label': instance.label,
    };
