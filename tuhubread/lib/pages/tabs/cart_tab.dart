import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tuhubread/l10n/app_localizations.dart';

import '../../blocs/cart/cart_cubit.dart';
import '../../blocs/cart/cart_state.dart';
import '../../models/user.model.dart';
import '../../widgets/cart_empty_view.dart';
import '../../widgets/cart_item_card.dart';
import '../../widgets/cart_summary_bar.dart';

class CartTab extends StatelessWidget {
  final UserModel user;

  const CartTab({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, cartState) {
        if (cartState.isEmpty) {
          return const CartEmptyView();
        }

        final l10n = AppLocalizations.of(context)!;
        final cubit = context.read<CartCubit>();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.cartItemsCount(cartState.totalQuantity.toString()),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF7F8C8D),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _confirmClearCart(context, cubit, l10n),
                    icon: const Icon(
                      Icons.delete_sweep_outlined,
                      size: 18,
                      color: Color(0xFFE74C3C),
                    ),
                    label: Text(
                      l10n.cartClearAll,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFE74C3C),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                physics: const BouncingScrollPhysics(),
                itemCount: cartState.items.length,
                itemBuilder: (context, index) {
                  final item = cartState.items[index];
                  return CartItemCard(
                    key: ValueKey(item.id),
                    item: item,
                    onIncrement: () => cubit.incrementQuantity(item.id),
                    onDecrement: () => cubit.decrementQuantity(item.id),
                    onRemove: () => cubit.removeItem(item.id),
                  );
                },
              ),
            ),
            CartSummaryBar(
              subtotal: cartState.subtotal,
              itemCount: cartState.totalQuantity,
              onCheckout: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.cartCheckoutComingSoon),
                    backgroundColor: const Color(0xFFE67E22),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _confirmClearCart(
    BuildContext context,
    CartCubit cubit,
    AppLocalizations l10n,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.cartClearAll),
        content: Text(l10n.cartClearAllConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cartCancel),
          ),
          TextButton(
            onPressed: () {
              cubit.clearCart();
              Navigator.of(dialogContext).pop();
            },
            child: Text(
              l10n.cartClearAll,
              style: const TextStyle(color: Color(0xFFE74C3C)),
            ),
          ),
        ],
      ),
    );
  }
}
