import 'package:json_annotation/json_annotation.dart';

part 'ward.model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class WardModel {
  final int code;
  final String name;
  final String divisionType;
  final String codename;
  final int? provinceCode;

  WardModel({
    required this.code,
    required this.name,
    required this.divisionType,
    required this.codename,
    this.provinceCode,
  });

  factory WardModel.fromJson(Map<String, dynamic> json) =>
      _$WardModelFromJson(json);

  Map<String, dynamic> toJson() => _$WardModelToJson(this);
}
