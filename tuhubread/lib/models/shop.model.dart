import 'package:json_annotation/json_annotation.dart';

part 'shop.model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ShopModel {
  @JsonKey(name: '_id')
  final String id;
  final String shopName;
  final String phone;
  final String avatar;
  final String banner;
  @JsonKey(defaultValue: 5.0)
  final double rating;
  final String status;

  ShopModel({
    required this.id,
    required this.shopName,
    required this.phone,
    required this.avatar,
    required this.banner,
    required this.rating,
    required this.status,
  });

  factory ShopModel.fromJson(Map<String, dynamic> json) =>
      _$ShopModelFromJson(json);

  Map<String, dynamic> toJson() => _$ShopModelToJson(this);
}
