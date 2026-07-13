import 'package:flutter/material.dart';

import '../models/product.model.dart';
import '../models/product_sale.model.dart';
import '../utils/currency_formatter.dart';

class ProductGridCard extends StatelessWidget {
  final ProductModel product;
  final ProductSaleModel? activeSale;
  final DateTime now;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;

  const ProductGridCard({
    super.key,
    required this.product,
    required this.activeSale,
    required this.now,
    this.onTap,
    this.onAddToCart,
  });

  String _formatCountdown(Duration d) {
    if (d.isNegative) return 'Hết hạn';
    if (d.inDays >= 1) return '${d.inDays}n ${d.inHours % 24}g';
    if (d.inHours >= 1) {
      return '${d.inHours.toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
    }
    return '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final hasSale = activeSale != null;
    final displayPrice = hasSale ? activeSale!.salePrice : product.price;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0x0A000000),
                blurRadius: 12,
                offset: const Offset(0, 4),
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
                      top: Radius.circular(18),
                    ),
                    child: Image.network(
                      product.image,
                      height: 110,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 110,
                        width: double.infinity,
                        color: const Color(0xFFF1EAE1),
                        child: const Icon(
                          Icons.bakery_dining,
                          color: Color(0xFFE67E22),
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                  if (hasSale)
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
                        child: const Text(
                          'SALE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (hasSale)
                    Positioned(
                      bottom: 4,
                      left: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.timer_outlined,
                                color: Colors.white,
                                size: 9,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                _formatCountdown(
                                  activeSale!.endDate.difference(now),
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.productName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        product.description,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF7F8C8D),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          if (product.rating > 0) ...[
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFF1C40F),
                              size: 12,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              "${product.rating}",
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF7F8C8D),
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              "•",
                              style: TextStyle(
                                fontSize: 9,
                                color: Color(0xFFBDC3C7),
                              ),
                            ),
                            const SizedBox(width: 5),
                          ],
                          Text(
                            "Đã bán ${product.salesCount}",
                            style: const TextStyle(
                              fontSize: 9,
                              color: Color(0xFFBDC3C7),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (hasSale)
                                Text(
                                  CurrencyFormatter.formatVND(product.price),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Color(0xFFBDC3C7),
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              Text(
                                CurrencyFormatter.formatVND(displayPrice),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE67E22),
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => onAddToCart?.call(),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFFE67E22),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
