import 'package:equatable/equatable.dart';

/// Một dòng sản phẩm trong giỏ hàng cá nhân, bao gồm cấu hình biến thể và tùy chọn.
class CartItemModel extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final String image;
  final String shopId;
  final String? shopName;
  final String variantId;
  final String variantName;
  final Set<String> selectedOptionIds;
  final List<String> selectedOptionNames;
  final int quantity;
  final double unitPrice;

  const CartItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.image,
    required this.shopId,
    this.shopName,
    required this.variantId,
    required this.variantName,
    required this.selectedOptionIds,
    required this.selectedOptionNames,
    required this.quantity,
    required this.unitPrice,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final optionsList = json['selected_options'] as List? ?? [];
    final optionIds = optionsList.map((e) => (e as Map)['option_id'] as String).toSet();
    final optionNames = optionsList.map((e) => (e as Map)['option_name'] as String).toList();
    return CartItemModel(
      id: json['_id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      image: json['product_image'] as String? ?? '',
      shopId: json['shop_id'] as String? ?? '',
      shopName: json['shop_name'] as String?,
      variantId: json['variant_id'] as String,
      variantName: json['variant_name'] as String,
      selectedOptionIds: optionIds,
      selectedOptionNames: optionNames,
      quantity: (json['quantity'] as num? ?? 1).toInt(),
      unitPrice: (json['unit_price'] as num? ?? 0).toDouble(),
    );
  }

  /// Khóa cấu hình duy nhất: product + variant + options (đã sắp xếp).
  static String buildConfigKey(
    String productId,
    String variantId,
    Set<String> optionIds,
  ) {
    final sortedOptions = optionIds.toList()..sort();
    return '$productId|$variantId|${sortedOptions.join(',')}';
  }

  double get lineTotal => unitPrice * quantity;

  CartItemModel copyWith({
    int? quantity,
  }) {
    return CartItemModel(
      id: id,
      productId: productId,
      productName: productName,
      image: image,
      shopId: shopId,
      shopName: shopName,
      variantId: variantId,
      variantName: variantName,
      selectedOptionIds: selectedOptionIds,
      selectedOptionNames: selectedOptionNames,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice,
    );
  }

  @override
  List<Object?> get props => [
        id,
        productId,
        productName,
        image,
        shopId,
        shopName,
        variantId,
        variantName,
        selectedOptionIds,
        selectedOptionNames,
        quantity,
        unitPrice,
      ];
}
