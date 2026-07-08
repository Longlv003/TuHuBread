import 'package:flutter/material.dart';
import 'package:tuhubread/l10n/app_localizations.dart';

class CustomerBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int cartItemCount;

  const CustomerBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.cartItemCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFE67E22),
        unselectedItemColor: const Color(0xFF95A5A6),
        selectedFontSize: 12,
        unselectedFontSize: 12,
        elevation: 0,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_rounded),
            label: l10n.tabHome,
          ),
          BottomNavigationBarItem(
            icon: _buildCartIcon(cartItemCount),
            label: l10n.tabCart,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history_rounded),
            label: l10n.tabHistory,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_rounded),
            label: l10n.tabProfile,
          ),
        ],
      ),
    );
  }

  Widget _buildCartIcon(int count) {
    if (count <= 0) {
      return const Icon(Icons.shopping_cart_rounded);
    }

    return Badge(
      label: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(fontSize: 10),
      ),
      backgroundColor: const Color(0xFFE74C3C),
      child: const Icon(Icons.shopping_cart_rounded),
    );
  }
}
