import 'package:flutter/material.dart';
import 'package:tuhubread/l10n/app_localizations.dart';

import '../utils/currency_formatter.dart';

class CartSummaryBar extends StatelessWidget {
  final double subtotal;
  final int itemCount;
  final VoidCallback? onCheckout;

  const CartSummaryBar({
    super.key,
    required this.subtotal,
    required this.itemCount,
    this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.cartSubtotal,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF7F8C8D),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.cartItemsCount(itemCount.toString()),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFBDC3C7),
                      ),
                    ),
                  ],
                ),
                Text(
                  CurrencyFormatter.formatVND(subtotal),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE74C3C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE67E22),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  l10n.cartCheckout,
                  style: const TextStyle(
                    fontSize: 15,
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
