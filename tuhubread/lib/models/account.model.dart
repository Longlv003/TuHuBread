import 'package:json_annotation/json_annotation.dart';

part 'account.model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class AccountModel {
  @JsonKey(name: 'firebase_uid')
  final String firebaseUid;

  @JsonKey(name: 'full_name', defaultValue: '')
  final String fullName;

  final String email;

  @JsonKey(name: 'avatar', defaultValue: '')
  final String avatarUrl;

  @JsonKey(defaultValue: 'user')
  final String role;

  AccountModel({
    required this.firebaseUid,
    required this.fullName,
    required this.email,
    required this.avatarUrl,
    required this.role,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) =>
      _$AccountModelFromJson(json);

  Map<String, dynamic> toJson() => _$AccountModelToJson(this);
}
