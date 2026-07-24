import 'package:flutter/material.dart';
import 'package:tuhubread/l10n/app_localizations.dart';
import '../../models/delivery_option.model.dart';
import '../../utils/currency_formatter.dart';

class CheckoutDeliveryOptionTile extends StatelessWidget {
  final DeliveryOptionModel option;
  final bool selected;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  const CheckoutDeliveryOptionTile({
    super.key,
    required this.option,
    required this.selected,
    required this.l10n,
    required this.onTap,
  });

  String _label() {
    switch (option.id) {
      case 'priority':
        return l10n.deliveryOptionPriorityLabel;
      case 'saving':
        return l10n.deliveryOptionSavingLabel;
      default:
        return l10n.deliveryOptionStandardLabel;
    }
  }

  String _desc() {
    switch (option.id) {
      case 'priority':
        return l10n.deliveryOptionPriorityDesc;
      case 'saving':
        return l10n.deliveryOptionSavingDesc;
      default:
        return l10n.deliveryOptionStandardDesc;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFDF0E5) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFFE67E22) : const Color(0xFFF1EAE1),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: 18,
              color: selected
                  ? const Color(0xFFE67E22)
                  : const Color(0xFFBDC3C7),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _label(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _desc(),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF7F8C8D),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              option.fee == 0
                  ? 'Miễn phí'
                  : CurrencyFormatter.formatVND(option.fee),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: option.fee == 0
                    ? const Color(0xFF27AE60)
                    : const Color(0xFFE67E22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
