import 'package:json_annotation/json_annotation.dart';

part 'category.model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class CategoryModel {
  @JsonKey(name: '_id')
  final String id;
  final String categoryName;
  final String categorySlug;
  final String categoryIcon;
  final String status;

  CategoryModel({
    required this.id,
    required this.categoryName,
    required this.categorySlug,
    required this.categoryIcon,
    required this.status,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) =>
      _$CategoryModelFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryModelToJson(this);
}
