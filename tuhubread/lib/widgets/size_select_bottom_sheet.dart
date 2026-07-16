import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/product_detail.model.dart';
import '../models/product_variant.model.dart';
import '../utils/cart_price_calculator.dart';
import '../utils/currency_formatter.dart';

/// Bottom sheet chọn size/variant nhanh, dùng khi bấm nút thêm-vào-giỏ
/// từ các danh sách sản phẩm (Home) mà không mở trang chi tiết.
/// Trả về variant được chọn, hoặc null nếu người dùng đóng sheet.
Future<ProductVariantModel?> showSizeSelectBottomSheet(
  BuildContext context,
  ProductDetailModel detail,
) {
  return showModalBottomSheet<ProductVariantModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SizeSelectSheet(detail: detail),
  );
}

class _SizeSelectSheet extends StatefulWidget {
  final ProductDetailModel detail;

  const _SizeSelectSheet({required this.detail});

  @override
  State<_SizeSelectSheet> createState() => _SizeSelectSheetState();
}

class _SizeSelectSheetState extends State<_SizeSelectSheet> {
  late ProductVariantModel _selected = widget.detail.variants.first;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final detail = widget.detail;
    final hasSaleProduct = detail.activeSale != null;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    detail.productName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF7F8C8D)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.detailSelectSize,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: detail.variants.map((variant) {
                final isSelected = variant.id == _selected.id;
                double displayPrice = variant.price;
                if (variant.salePrice != null) {
                  displayPrice = variant.salePrice!;
                } else if (hasSaleProduct) {
                  final activeSale = detail.activeSale!;
                  if (activeSale.variantId == null ||
                      activeSale.variantId == variant.id) {
                    displayPrice = activeSale.salePrice;
                  }
                }

                return GestureDetector(
                  onTap: () => setState(() => _selected = variant),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? const Color(0xFFFDF0E5) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFE67E22)
                            : const Color(0xFFF1EAE1),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          variant.variantName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? const Color(0xFFD35400)
                                : const Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.formatVND(displayPrice),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? const Color(0xFFD35400)
                                : const Color(0xFFE67E22),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE67E22),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(_selected),
                child: Text(
                  '${l10n.detailAddToCart} · ${CurrencyFormatter.formatVND(
                    CartPriceCalculator.calculateUnitPrice(
                      detail,
                      _selected,
                      const {},
                    ),
                  )}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
