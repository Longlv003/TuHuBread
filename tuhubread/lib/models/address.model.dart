import 'package:json_annotation/json_annotation.dart';

part 'address.model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class AddressModel {
  @JsonKey(name: '_id')
  final String id;
  final String receiverName;
  final String receiverPhone;
  final String addressDetail;
  @JsonKey(defaultValue: false)
  final bool isDefault;

  AddressModel({
    required this.id,
    required this.receiverName,
    required this.receiverPhone,
    required this.addressDetail,
    required this.isDefault,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) =>
      _$AddressModelFromJson(json);

  Map<String, dynamic> toJson() => _$AddressModelToJson(this);
}
