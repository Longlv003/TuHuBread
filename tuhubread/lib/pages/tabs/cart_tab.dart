import 'package:flutter/material.dart';
import 'package:tuhubread/l10n/app_localizations.dart';
import '../../models/user.model.dart';

class CartTab extends StatelessWidget {
  final UserModel user;

  const CartTab({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_cart_outlined, size: 64, color: Color(0xFFBDC3C7)),
            const SizedBox(height: 16),
            Text(
              l10n.cartEmpty,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF7F8C8D)),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.cartEmptySub,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFBDC3C7), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
