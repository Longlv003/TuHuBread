import 'package:flutter/material.dart';
import 'package:tuhubread/l10n/app_localizations.dart';
import '../../models/address.model.dart';
import '../../utils/address_label.dart';

class CheckoutEmptyAddress extends StatelessWidget {
  final AppLocalizations l10n;
  final VoidCallback onAdd;

  const CheckoutEmptyAddress({
    super.key,
    required this.l10n,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          l10n.checkoutNoAddressTitle,
          style: const TextStyle(fontSize: 13, color: Color(0xFF7F8C8D)),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(
              Icons.add_location_alt_outlined,
              size: 18,
              color: Color(0xFFE67E22),
            ),
            label: Text(
              l10n.checkoutAddAddressButton,
              style: const TextStyle(color: Color(0xFFE67E22)),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE67E22)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}

class CheckoutAddressSummary extends StatelessWidget {
  final AddressModel address;
  final AppLocalizations l10n;

  const CheckoutAddressSummary({
    super.key,
    required this.address,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          addressLabelIcon(address.label),
          size: 18,
          color: const Color(0xFFE67E22),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${address.receiverName} · ${address.receiverPhone}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address.addressDetail,
                style: const TextStyle(fontSize: 12, color: Color(0xFF7F8C8D)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
