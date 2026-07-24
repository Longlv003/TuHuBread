import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/product_detail.model.dart';
import '../models/product_variant.model.dart';
import '../utils/cart_price_calculator.dart';
import '../utils/currency_formatter.dart';

class ProductSelectionResult {
  final ProductVariantModel variant;
  final Set<String> selectedOptionIds;
  final int quantity;

  ProductSelectionResult({
    required this.variant,
    required this.selectedOptionIds,
    required this.quantity,
  });
}

/// Bottom sheet chọn size/variant và options nhanh, dùng khi bấm nút thêm-vào-giỏ
/// từ các danh sách sản phẩm (Home) mà không mở trang chi tiết.
/// Trả về ProductSelectionResult, hoặc null nếu người dùng đóng sheet.
Future<ProductSelectionResult?> showSizeSelectBottomSheet(
  BuildContext context,
  ProductDetailModel detail,
) {
  return showModalBottomSheet<ProductSelectionResult>(
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
  final Set<String> _selectedOptionIds = {};
  int _quantity = 1;

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
            
            // Size Selection Section (Only show if there are multiple variants)
            if (detail.variants.length > 1) ...[
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
            ],

            // Extra Options Section (Only show if there are options available)
            if (detail.options.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                l10n.detailExtraOptions,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.3,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  itemCount: detail.options.length,
                  separatorBuilder: (c, i) =>
                      const Divider(height: 1, color: Color(0xFFFDF9F3)),
                  itemBuilder: (context, idx) {
                    final option = detail.options[idx];
                    final isChecked = _selectedOptionIds.contains(option.id);

                    return InkWell(
                      onTap: () => setState(() {
                        if (isChecked) {
                          _selectedOptionIds.remove(option.id);
                        } else {
                          _selectedOptionIds.add(option.id);
                        }
                      }),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 4.0,
                        ),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: isChecked
                                    ? const Color(0xFFE67E22)
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isChecked
                                      ? const Color(0xFFE67E22)
                                      : const Color(0xFFBDC3C7),
                                  width: 1.5,
                                ),
                              ),
                              child: isChecked
                                  ? const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 14,
                                    )
                                  : const SizedBox(width: 14, height: 14),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                option.optionName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                            ),
                            Text(
                              "+${CurrencyFormatter.formatVND(option.extraPrice)}",
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF7F8C8D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

             const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Số lượng',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 16, color: Color(0xFFE67E22)),
                        onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                      ),
                      Text(
                        '$_quantity',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 16, color: Color(0xFFE67E22)),
                        onPressed: () => setState(() => _quantity++),
                      ),
                    ],
                  ),
                ),
              ],
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
                onPressed: () => Navigator.of(context).pop(
                  ProductSelectionResult(
                    variant: _selected,
                    selectedOptionIds: _selectedOptionIds,
                    quantity: _quantity,
                  ),
                ),
                child: Text(
                  '${l10n.detailAddToCart} · ${CurrencyFormatter.formatVND(
                    CartPriceCalculator.calculateUnitPrice(
                      detail,
                      _selected,
                      _selectedOptionIds,
                    ) * _quantity,
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
