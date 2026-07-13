import 'package:flutter/material.dart';

import '../models/product.model.dart';
import '../utils/currency_formatter.dart';

/// Thẻ sản phẩm gợi ý thêm vào giỏ (vd: đồ uống), hiển thị dạng lưới ngang
/// kèm nút "+" để thêm nhanh không cần vào màn chi tiết chọn biến thể.
class CartSuggestionCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onAdd;

  const CartSuggestionCard({
    super.key,
    required this.product,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Container(
        width: 112,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF1EAE1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                product.image,
                height: 56,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  height: 56,
                  width: double.infinity,
                  color: const Color(0xFFF1EAE1),
                  child: const Icon(
                    Icons.local_drink_outlined,
                    color: Color(0xFFE67E22),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.productName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    CurrencyFormatter.formatVND(product.price),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE74C3C),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onAdd,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE67E22),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
