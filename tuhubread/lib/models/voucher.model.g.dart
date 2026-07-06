// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voucher.model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VoucherModel _$VoucherModelFromJson(Map<String, dynamic> json) => VoucherModel(
  id: json['_id'] as String,
  shopId: json['shop_id'] as String?,
  voucherCode: json['voucher_code'] as String,
  voucherName: json['voucher_name'] as String,
  voucherType: json['voucher_type'] as String,
  discountType: json['discount_type'] as String,
  discountValue: (json['discount_value'] as num).toDouble(),
  minOrderAmount: (json['min_order_amount'] as num).toDouble(),
  maxDiscountAmount: (json['max_discount_amount'] as num?)?.toDouble(),
  claimLimit: (json['claim_limit'] as num?)?.toInt(),
  claimedCount: (json['claimed_count'] as num?)?.toInt() ?? 0,
  usageLimit: (json['usage_limit'] as num?)?.toInt(),
  usedCount: (json['used_count'] as num?)?.toInt() ?? 0,
  startDate: DateTime.parse(json['start_date'] as String),
  endDate: DateTime.parse(json['end_date'] as String),
  status: json['status'] as String,
);

Map<String, dynamic> _$VoucherModelToJson(VoucherModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'shop_id': instance.shopId,
      'voucher_code': instance.voucherCode,
      'voucher_name': instance.voucherName,
      'voucher_type': instance.voucherType,
      'discount_type': instance.discountType,
      'discount_value': instance.discountValue,
      'min_order_amount': instance.minOrderAmount,
      'max_discount_amount': instance.maxDiscountAmount,
      'claim_limit': instance.claimLimit,
      'claimed_count': instance.claimedCount,
      'usage_limit': instance.usageLimit,
      'used_count': instance.usedCount,
      'start_date': instance.startDate.toIso8601String(),
      'end_date': instance.endDate.toIso8601String(),
      'status': instance.status,
    };
