import 'package:flutter/material.dart';
import '../models/product.model.dart';
import '../utils/currency_formatter.dart';
import 'app_network_image.dart';
import 'tap_scale.dart';

class HorizontalProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;

  /// Chiều cao cố định của thẻ. Nơi nào đặt thẻ vào danh sách ngang PHẢI dùng
  /// đúng hằng số này cho khung chứa — trước đây mỗi màn tự đặt 200/205px,
  /// thấp hơn nội dung khi món vừa giảm giá vừa có tên 2 dòng, gây tràn 6px.
  /// Mọi khối bên trong đều có chiều cao cố định nên tổng luôn bằng đúng
  /// số này, không phụ thuộc chữ dài ngắn.
  static const double height =
      _imageHeight +
      _padding * 2 +
      _titleHeight +
      _gapAfterTitle +
      _descriptionHeight +
      _gapBeforePrice +
      _priceRowHeight;

  static const double _imageHeight = 100;
  static const double _padding = 8;
  static const double _titleHeight = 30; // 2 dòng @12px
  static const double _gapAfterTitle = 3;
  static const double _descriptionHeight = 22; // 2 dòng @9px
  static const double _gapBeforePrice = 6;
  static const double _priceRowHeight = 31;

  const HorizontalProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: TapScale(
        onTap: onTap,
        child: Container(
          width: 150,
          height: height,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0x08000000),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: AppNetworkImage(
                      url: product.image,
                      height: _imageHeight,
                      width: 150,
                      fallbackIconSize: 30,
                    ),
                  ),
                  if (product.hasDiscount)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE74C3C),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '-${product.discountPercent}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(_padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mỗi khối chữ chiếm đúng chiều cao cố định dù nội dung
                    // ngắn hay dài -> giá và nút "+" của mọi thẻ luôn thẳng
                    // hàng nhau, và tổng chiều cao không bao giờ vượt khung.
                    SizedBox(
                      height: _titleHeight,
                      child: Text(
                        product.productName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: _gapAfterTitle),
                    SizedBox(
                      height: _descriptionHeight,
                      child: Text(
                        product.description ?? '',
                        style: const TextStyle(
                          fontSize: 9,
                          color: Color(0xFF7F8C8D),
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: _gapBeforePrice),
                    SizedBox(
                      height: _priceRowHeight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // Luôn chừa dòng giá gốc (ẩn khi không giảm
                                // giá) để giá bán của các thẻ nằm cùng một
                                // đường, không bị nhấp nhô.
                                Text(
                                  product.hasDiscount
                                      ? CurrencyFormatter.formatVND(
                                          product.price,
                                        )
                                      : '',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Color(0xFFBDC3C7),
                                    decoration: TextDecoration.lineThrough,
                                    height: 1.2,
                                  ),
                                  maxLines: 1,
                                ),
                                Text(
                                  CurrencyFormatter.formatVND(
                                    product.displayPrice,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFE67E22),
                                    height: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => onAddToCart?.call(),
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Color(0xFFE67E22),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
