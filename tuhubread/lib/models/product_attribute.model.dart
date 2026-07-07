import 'package:json_annotation/json_annotation.dart';

part 'product_attribute.model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ProductAttributeModel {
  @JsonKey(name: '_id')
  final String id;
  final String productId;
  final String attributeKey;
  final String attributeLabel;
  final String attributeValue;
  final int sortOrder;
  final String status;

  ProductAttributeModel({
    required this.id,
    required this.productId,
    required this.attributeKey,
    required this.attributeLabel,
    required this.attributeValue,
    required this.sortOrder,
    required this.status,
  });

  factory ProductAttributeModel.fromJson(Map<String, dynamic> json) =>
      _$ProductAttributeModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductAttributeModelToJson(this);
}
