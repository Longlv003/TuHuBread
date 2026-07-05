// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account.model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccountModel _$AccountModelFromJson(Map<String, dynamic> json) => AccountModel(
  firebaseUid: json['firebase_uid'] as String,
  fullName: json['full_name'] as String? ?? '',
  email: json['email'] as String,
  avatarUrl: json['avatar'] as String? ?? '',
  role: json['role'] as String? ?? 'user',
);

Map<String, dynamic> _$AccountModelToJson(AccountModel instance) =>
    <String, dynamic>{
      'firebase_uid': instance.firebaseUid,
      'full_name': instance.fullName,
      'email': instance.email,
      'avatar': instance.avatarUrl,
      'role': instance.role,
    };
