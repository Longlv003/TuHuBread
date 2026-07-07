// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_review.model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductReviewUserModel _$ProductReviewUserModelFromJson(
  Map<String, dynamic> json,
) => ProductReviewUserModel(
  fullName: json['full_name'] as String,
  avatar: json['avatar'] as String?,
);

Map<String, dynamic> _$ProductReviewUserModelToJson(
  ProductReviewUserModel instance,
) => <String, dynamic>{
  'full_name': instance.fullName,
  'avatar': instance.avatar,
};

ProductReviewModel _$ProductReviewModelFromJson(
  Map<String, dynamic> json,
) => ProductReviewModel(
  id: json['_id'] as String,
  rating: (json['rating'] as num).toDouble(),
  comment: json['comment'] as String?,
  images:
      (json['images'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      [],
  createdAt: json['created_at'] as String,
  user: ProductReviewUserModel.fromJson(json['user'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ProductReviewModelToJson(ProductReviewModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'rating': instance.rating,
      'comment': instance.comment,
      'images': instance.images,
      'created_at': instance.createdAt,
      'user': instance.user,
    };
