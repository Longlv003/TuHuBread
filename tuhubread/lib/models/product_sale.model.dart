import 'package:json_annotation/json_annotation.dart';

part 'product_sale.model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ProductSaleModel {
  @JsonKey(name: '_id')
  final String id;
  final String productId;
  final String? variantId;
  final String saleName;
  final double salePrice;
  final int? saleLimit;
  final int soldQuantity;
  final DateTime startDate;
  final DateTime endDate;
  final String status; // active / inactive / expired

  ProductSaleModel({
    required this.id,
    required this.productId,
    this.variantId,
    required this.saleName,
    required this.salePrice,
    this.saleLimit,
    required this.soldQuantity,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  /// Kiểm tra xem đợt sale có đang diễn ra không (countdown hợp lệ)
  bool get isActiveNow {
    final now = DateTime.now().toUtc();
    return status == 'active' &&
        now.isAfter(startDate.toUtc()) &&
        now.isBefore(endDate.toUtc()) &&
        (saleLimit == null || soldQuantity < saleLimit!);
  }

  factory ProductSaleModel.fromJson(Map<String, dynamic> json) =>
      _$ProductSaleModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductSaleModelToJson(this);
}
