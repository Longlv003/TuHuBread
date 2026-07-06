import 'package:json_annotation/json_annotation.dart';

part 'voucher_save.model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class VoucherSaveModel {
  @JsonKey(name: '_id')
  final String id;

  final String voucherId;
  final String userId;
  final String voucherCode;    // snapshot mã lúc save
  final DateTime expiresAt;    // snapshot end_date lúc save
  final String status;         // saved / used / expired
  final DateTime savedAt;
  final DateTime? usedAt;

  VoucherSaveModel({
    required this.id,
    required this.voucherId,
    required this.userId,
    required this.voucherCode,
    required this.expiresAt,
    required this.status,
    required this.savedAt,
    this.usedAt,
  });

  bool get isUsed => status == 'used';
  bool get isExpired =>
      status == 'expired' || expiresAt.isBefore(DateTime.now());
  bool get isAvailable => status == 'saved' && !isExpired;

  factory VoucherSaveModel.fromJson(Map<String, dynamic> json) =>
      _$VoucherSaveModelFromJson(json);

  Map<String, dynamic> toJson() => _$VoucherSaveModelToJson(this);
}
