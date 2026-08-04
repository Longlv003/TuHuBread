import 'package:json_annotation/json_annotation.dart';

part 'shop.model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ShopModel {
  @JsonKey(name: '_id')
  final String id;
  final String shopName;
  @JsonKey(name: 'phone_number')
  final String phone;
  final String logo;
  final String banner;
  @JsonKey(name: 'rating_average')
  final double? rating;
  final String status;
  final String address;
  @JsonKey(name: 'distance_km')
  final double? distanceKm;

  ShopModel({
    required this.id,
    required this.shopName,
    required this.phone,
    required this.logo,
    required this.banner,
    this.rating,
    required this.status,
    required this.address,
    this.distanceKm,
  });

  factory ShopModel.fromJson(Map<String, dynamic> json) =>
      _$ShopModelFromJson(json);

  Map<String, dynamic> toJson() => _$ShopModelToJson(this);
}
