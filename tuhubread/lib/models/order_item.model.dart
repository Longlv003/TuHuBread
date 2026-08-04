class OrderItemModel {
  final String id;
  final String productId;
  final String productName;
  final String variantName;
  final String? productImage;
  final double unitPrice;
  final int quantity;
  final double subtotal;
  final bool isReviewed;

  OrderItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.variantName,
    this.productImage,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
    this.isReviewed = false,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['_id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      variantName: json['variant_name'] as String,
      productImage: json['product_image'] as String?,
      unitPrice: (json['unit_price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      subtotal: (json['subtotal'] as num).toDouble(),
      isReviewed: json['is_reviewed'] as bool? ?? false,
    );
  }

  OrderItemModel copyWith({bool? isReviewed}) {
    return OrderItemModel(
      id: id,
      productId: productId,
      productName: productName,
      variantName: variantName,
      productImage: productImage,
      unitPrice: unitPrice,
      quantity: quantity,
      subtotal: subtotal,
      isReviewed: isReviewed ?? this.isReviewed,
    );
  }
}
