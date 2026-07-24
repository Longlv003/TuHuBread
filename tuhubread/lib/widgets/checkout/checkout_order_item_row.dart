import 'package:flutter/material.dart';
import '../../models/cart_item.model.dart';
import '../../utils/currency_formatter.dart';

class CheckoutOrderItemRow extends StatelessWidget {
  final CartItemModel item;

  const CheckoutOrderItemRow({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${item.productName} x${item.quantity}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF2C3E50)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            CurrencyFormatter.formatVND(item.lineTotal),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7F8C8D),
            ),
          ),
        ],
      ),
    );
  }
}
