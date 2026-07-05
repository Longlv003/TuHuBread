import 'package:json_annotation/json_annotation.dart';

part 'user.model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class UserModel {
  @JsonKey(name: 'firebase_uid')
  final String firebaseUid;

  @JsonKey(name: 'full_name', defaultValue: '')
  final String fullName;

  final String? email;

  @JsonKey(name: 'avatar')
  final String? avatarUrl;

  @JsonKey(defaultValue: 'customer')
  final String role;

  @JsonKey(defaultValue: 'active')
  final String status;

  UserModel({
    required this.firebaseUid,
    required this.fullName,
    this.email,
    this.avatarUrl,
    required this.role,
    required this.status,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}
