import 'package:json_annotation/json_annotation.dart';

part 'province.model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ProvinceModel {
  final int code;
  final String name;
  final String divisionType;
  final String codename;
  final int? phoneCode;

  ProvinceModel({
    required this.code,
    required this.name,
    required this.divisionType,
    required this.codename,
    this.phoneCode,
  });

  factory ProvinceModel.fromJson(Map<String, dynamic> json) =>
      _$ProvinceModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProvinceModelToJson(this);
}
