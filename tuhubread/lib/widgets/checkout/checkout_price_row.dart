import 'package:flutter/material.dart';
import '../../utils/currency_formatter.dart';

class CheckoutPriceRow extends StatelessWidget {
  final String label;
  final double value;
  final bool emphasize;

  const CheckoutPriceRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: emphasize ? 14 : 12,
            fontWeight: emphasize ? FontWeight.bold : FontWeight.normal,
            color: const Color(0xFF2C3E50),
          ),
        ),
        Text(
          CurrencyFormatter.formatVND(value),
          style: TextStyle(
            fontSize: emphasize ? 16 : 12,
            fontWeight: emphasize ? FontWeight.bold : emphasize ? FontWeight.bold : FontWeight.normal,
            color: emphasize
                ? const Color(0xFFE74C3C)
                : const Color(0xFF2C3E50),
          ),
        ),
      ],
    );
  }
}
