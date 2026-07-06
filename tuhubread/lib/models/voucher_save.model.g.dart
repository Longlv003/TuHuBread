// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voucher_save.model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VoucherSaveModel _$VoucherSaveModelFromJson(Map<String, dynamic> json) =>
    VoucherSaveModel(
      id: json['_id'] as String,
      voucherId: json['voucher_id'] as String,
      userId: json['user_id'] as String,
      voucherCode: json['voucher_code'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      status: json['status'] as String,
      savedAt: DateTime.parse(json['saved_at'] as String),
      usedAt: json['used_at'] == null
          ? null
          : DateTime.parse(json['used_at'] as String),
    );

Map<String, dynamic> _$VoucherSaveModelToJson(VoucherSaveModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'voucher_id': instance.voucherId,
      'user_id': instance.userId,
      'voucher_code': instance.voucherCode,
      'expires_at': instance.expiresAt.toIso8601String(),
      'status': instance.status,
      'saved_at': instance.savedAt.toIso8601String(),
      'used_at': instance.usedAt?.toIso8601String(),
    };
