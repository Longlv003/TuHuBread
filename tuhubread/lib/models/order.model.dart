class OrderModel {
  final String id;
  final String orderCode;
  final String paymentMethod;
  final String paymentStatus;
  final String orderStatus;
  final double itemsTotal;
  final double discountAmount;
  final double deliveryFee;
  final double totalAmount;
  final String? note;
  final DateTime createdAt;
  final String? shopName;
  final String? shopLogo;
  final String? shopPhone;
  final String? receiverName;
  final String? receiverPhone;
  final String? addressDetail;

  OrderModel({
    required this.id,
    required this.orderCode,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.orderStatus,
    required this.itemsTotal,
    required this.discountAmount,
    required this.deliveryFee,
    required this.totalAmount,
    this.note,
    required this.createdAt,
    this.shopName,
    this.shopLogo,
    this.shopPhone,
    this.receiverName,
    this.receiverPhone,
    this.addressDetail,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final shop = json['shop'] as Map<String, dynamic>?;
    final address = json['address_id'] as Map<String, dynamic>?;
    return OrderModel(
      id: json['_id'] as String,
      orderCode: json['order_code'] as String,
      paymentMethod: json['payment_method'] as String,
      paymentStatus: json['payment_status'] as String,
      orderStatus: json['order_status'] as String,
      itemsTotal: (json['items_total'] as num).toDouble(),
      discountAmount: (json['discount_amount'] as num? ?? 0).toDouble(),
      deliveryFee: (json['delivery_fee'] as num? ?? 0).toDouble(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      shopName: shop?['shop_name'] as String?,
      shopLogo: shop?['logo'] as String?,
      shopPhone: shop?['phone'] as String?,
      receiverName: address?['receiver_name'] as String?,
      receiverPhone: address?['receiver_phone'] as String?,
      addressDetail: address?['address_detail'] as String?,
    );
  }
}
