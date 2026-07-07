import 'package:json_annotation/json_annotation.dart';

part 'product_option.model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ProductOptionModel {
  @JsonKey(name: '_id')
  final String id;
  final String productId;
  final String optionName;
  final String optionSlug;
  final double extraPrice;
  final String status;

  ProductOptionModel({
    required this.id,
    required this.productId,
    required this.optionName,
    required this.optionSlug,
    required this.extraPrice,
    required this.status,
  });

  factory ProductOptionModel.fromJson(Map<String, dynamic> json) =>
      _$ProductOptionModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductOptionModelToJson(this);
}
