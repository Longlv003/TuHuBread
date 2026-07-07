import 'package:json_annotation/json_annotation.dart';

part 'product_review.model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ProductReviewUserModel {
  final String fullName;
  final String? avatar;

  ProductReviewUserModel({
    required this.fullName,
    this.avatar,
  });

  factory ProductReviewUserModel.fromJson(Map<String, dynamic> json) =>
      _$ProductReviewUserModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductReviewUserModelToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class ProductReviewModel {
  @JsonKey(name: '_id')
  final String id;
  final double rating;
  final String? comment;
  @JsonKey(defaultValue: [])
  final List<String> images;
  final String createdAt;
  final ProductReviewUserModel user;

  ProductReviewModel({
    required this.id,
    required this.rating,
    this.comment,
    required this.images,
    required this.createdAt,
    required this.user,
  });

  factory ProductReviewModel.fromJson(Map<String, dynamic> json) =>
      _$ProductReviewModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductReviewModelToJson(this);
}
