// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  firebaseUid: json['firebase_uid'] as String,
  fullName: json['full_name'] as String? ?? '',
  email: json['email'] as String?,
  avatarUrl: json['avatar'] as String?,
  role: json['role'] as String? ?? 'customer',
  status: json['status'] as String? ?? 'active',
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'firebase_uid': instance.firebaseUid,
  'full_name': instance.fullName,
  'email': instance.email,
  'avatar': instance.avatarUrl,
  'role': instance.role,
  'status': instance.status,
};
