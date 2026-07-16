// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ward.model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WardModel _$WardModelFromJson(Map<String, dynamic> json) => WardModel(
  code: (json['code'] as num).toInt(),
  name: json['name'] as String,
  divisionType: json['division_type'] as String,
  codename: json['codename'] as String,
  provinceCode: (json['province_code'] as num?)?.toInt(),
);

Map<String, dynamic> _$WardModelToJson(WardModel instance) => <String, dynamic>{
  'code': instance.code,
  'name': instance.name,
  'division_type': instance.divisionType,
  'codename': instance.codename,
  'province_code': instance.provinceCode,
};
