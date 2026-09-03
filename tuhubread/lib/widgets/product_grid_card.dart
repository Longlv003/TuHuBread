import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/product.model.dart';
import '../utils/currency_formatter.dart';
import 'app_network_image.dart';
import 'tap_scale.dart';

class ProductGridCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;

  /// Tên chi nhánh — chỉ truyền vào khi đang hiển thị món trộn từ nhiều chi
  /// nhánh (chưa chọn 1 chi nhánh cụ thể), để khách biết món này của chi
  /// nhánh nào trước khi bấm vào.
  final String? shopName;

  const ProductGridCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
    this.shopName,
  });

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: TapScale(
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
                    child: AppNetworkImage(
                      url: product.image,
                      height: 110,
                      width: double.infinity,
                      fallbackIconSize: 36,
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
                      // Luôn chiếm đúng 2 dòng dù có mô tả hay không, để các
                      // thẻ trong lưới thẳng hàng nhau — trước đây món thiếu
                      // mô tả bị co lại làm dòng "Đã bán" nhô lên lệch hẳn so
                      // với thẻ bên cạnh.
                      SizedBox(
                        height: 26,
                        width: double.infinity,
                        child: Text(
                          product.description ?? '',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF7F8C8D),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Luôn hiện cả sao lẫn số đã bán (0 nếu chưa có) thay vì
                      // ẩn phần sao — giữ chiều cao đồng nhất giữa các thẻ.
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: product.rating > 0
                                ? const Color(0xFFF1C40F)
                                : const Color(0xFFD5DBDB),
                            size: 12,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            product.rating > 0
                                ? product.rating.toStringAsFixed(1)
                                : '0',
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
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.detailSoldAmount(
                                product.salesCount,
                              ),
                              style: const TextStyle(
                                fontSize: 9,
                                color: Color(0xFFBDC3C7),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Có khuyến mãi thì gạch giá gốc và hiện giá
                              // giảm — nếu chỉ hiện product.price như trước,
                              // khách sẽ thấy giá khác với giá thực trả.
                              if (product.hasDiscount)
                                Text(
                                  CurrencyFormatter.formatVND(product.price),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Color(0xFFBDC3C7),
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              Text(
                                CurrencyFormatter.formatVND(
                                  product.displayPrice,
                                ),
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
