import 'package:tuhubread/configs/system.dart';

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
  final int itemsCount;
  final int reviewedCount;

  /// true nếu đơn đã hoàn thành nhưng còn sản phẩm nào đó chưa được đánh giá.
  bool get needsReview =>
      orderStatus.toLowerCase() == 'completed' && reviewedCount < itemsCount;

  bool get allReviewed => itemsCount > 0 && reviewedCount >= itemsCount;

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
    this.itemsCount = 0,
    this.reviewedCount = 0,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final shop = (json['shop_id'] ?? json['shop']) as Map<String, dynamic>?;
    final addressObj = json['address_id'];
    final address = addressObj is Map<String, dynamic> ? addressObj : null;

    String? logoUrl = shop?['logo'] as String?;
    if (logoUrl != null && !logoUrl.startsWith('http')) {
      logoUrl = '${URL.getBaseURL()}/images/shops/${logoUrl.split('/').last}';
    }

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
      shopLogo: logoUrl,
      shopPhone: (shop?['phone_number'] ?? shop?['phone']) as String?,
      receiverName: address?['receiver_name'] as String?,
      receiverPhone: address?['receiver_phone'] as String?,
      addressDetail: address?['address_detail'] as String?,
      itemsCount: (json['items_count'] as num?)?.toInt() ?? 0,
      reviewedCount: (json['reviewed_count'] as num?)?.toInt() ?? 0,
    );
  }

  OrderModel copyWith({int? reviewedCount}) {
    return OrderModel(
      id: id,
      orderCode: orderCode,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      orderStatus: orderStatus,
      itemsTotal: itemsTotal,
      discountAmount: discountAmount,
      deliveryFee: deliveryFee,
      totalAmount: totalAmount,
      note: note,
      createdAt: createdAt,
      shopName: shopName,
      shopLogo: shopLogo,
      shopPhone: shopPhone,
      receiverName: receiverName,
      receiverPhone: receiverPhone,
      addressDetail: addressDetail,
      itemsCount: itemsCount,
      reviewedCount: reviewedCount ?? this.reviewedCount,
    );
  }
}
