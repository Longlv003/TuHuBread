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

  /// Cửa hàng có đang mở bán không (chủ shop tự bật/tắt trong trang quản trị).
  /// Quán đang đóng vẫn hiện trong danh sách nhưng không cho đặt hàng.
  @JsonKey(name: 'is_open', defaultValue: true)
  final bool isOpen;

  /// Giờ mở/đóng cửa dạng "HH:mm" — dùng để nói rõ cho khách biết khi nào
  /// quán mở lại, thay vì chỉ báo cụt lủn là "đã đóng".
  final String? openTime;
  final String? closeTime;

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
    this.isOpen = true,
    this.openTime,
    this.closeTime,
  });

  factory ShopModel.fromJson(Map<String, dynamic> json) =>
      _$ShopModelFromJson(json);

  Map<String, dynamic> toJson() => _$ShopModelToJson(this);
}
