import 'package:json_annotation/json_annotation.dart';

part 'voucher.model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class VoucherModel {
  @JsonKey(name: '_id')
  final String id;

  final String? shopId;
  final String voucherCode;
  final String voucherName;
  final String voucherType;      // platform / shop
  final String discountType;     // percent / amount / free_shipping
  final double discountValue;
  final double minOrderAmount;
  final double? maxDiscountAmount;

  // Claim (save) fields
  final int? claimLimit;         // null = không giới hạn người save
  @JsonKey(defaultValue: 0)
  final int claimedCount;        // số người đã save

  // Usage fields
  final int? usageLimit;
  @JsonKey(defaultValue: 0)
  final int usedCount;

  final DateTime startDate;
  final DateTime endDate;
  final String status;           // active / inactive / expired

  VoucherModel({
    required this.id,
    this.shopId,
    required this.voucherCode,
    required this.voucherName,
    required this.voucherType,
    required this.discountType,
    required this.discountValue,
    required this.minOrderAmount,
    this.maxDiscountAmount,
    this.claimLimit,
    required this.claimedCount,
    this.usageLimit,
    required this.usedCount,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  /// Số mã còn lại có thể save. Null = không giới hạn.
  int? get remainingClaims =>
      claimLimit == null ? null : claimLimit! - claimedCount;

  /// Voucher còn mã để save không?
  bool get canBeClaimed =>
      status == 'active' &&
      endDate.isAfter(DateTime.now()) &&
      (claimLimit == null || claimedCount < claimLimit!);

  factory VoucherModel.fromJson(Map<String, dynamic> json) =>
      _$VoucherModelFromJson(json);

  Map<String, dynamic> toJson() => _$VoucherModelToJson(this);
}
