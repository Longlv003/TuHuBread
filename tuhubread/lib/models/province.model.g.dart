// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'province.model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProvinceModel _$ProvinceModelFromJson(Map<String, dynamic> json) =>
    ProvinceModel(
      code: (json['code'] as num).toInt(),
      name: json['name'] as String,
      divisionType: json['division_type'] as String,
      codename: json['codename'] as String,
      phoneCode: (json['phone_code'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ProvinceModelToJson(ProvinceModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'division_type': instance.divisionType,
      'codename': instance.codename,
      'phone_code': instance.phoneCode,
    };
