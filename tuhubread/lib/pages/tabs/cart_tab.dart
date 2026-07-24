import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart' as getx;
import 'package:tuhubread/l10n/app_localizations.dart';

import '../../blocs/cart/cart_cubit.dart';
import '../../blocs/cart/cart_state.dart';
import '../../blocs/home/home_cubit.dart';
import '../../blocs/home/home_state.dart';
import '../../helpers/cart_action_helper.dart';
import '../../models/product.model.dart';
import '../../models/user.model.dart';
import '../checkout_page.dart';
import '../../widgets/cart_empty_view.dart';
import '../../widgets/cart_item_card.dart';
import '../../widgets/cart_summary_bar.dart';
import '../../widgets/cart_suggestion_card.dart';
import '../../widgets/app_confirm_dialog.dart';

class CartTab extends StatelessWidget {
  final UserModel user;

  const CartTab({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, cartState) {
        if (cartState.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => context.read<CartCubit>().loadCart(),
            color: const Color(0xFFE67E22),
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: constraints.maxHeight,
                  child: const CartEmptyView(),
                ),
              ),
            ),
          );
        }

        final l10n = AppLocalizations.of(context)!;
        final cubit = context.read<CartCubit>();
        final homeState = context.watch<HomeCubit>().state;
        final suggestions = _drinkSuggestions(homeState, cartState);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
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
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => cubit.loadCart(),
                color: const Color(0xFFE67E22),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  for (final item in cartState.items)
                    CartItemCard(
                      key: ValueKey(item.id),
                      item: item,
                      onIncrement: () => cubit.incrementQuantity(item.id),
                      onDecrement: () => cubit.decrementQuantity(
                        item.id,
                        confirmShow: () => _showRemoveConfirm(context, item.productName),
                      ),
                      onRemove: () => cubit.removeItem(
                        item.id,
                        confirmShow: () => _showRemoveConfirm(context, item.productName),
                      ),
                    ),
                  if (suggestions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.cartSuggestionTitle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 128,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: suggestions.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final product = suggestions[index];
                          return CartSuggestionCard(
                            product: product,
                            onAdd: () =>
                                CartActionHelper.quickAddProductWithFeedback(
                                  context,
                                  product.id,
                                  successMessage: l10n.detailAddedToCart,
                                  failureFallback: l10n.cartAddFailed,
                                ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          CartSummaryBar(
              subtotal: cartState.subtotal,
              itemCount: cartState.totalQuantity,
              onCheckout: () => getx.Get.to(
                () => CheckoutPage(
                  items: cartState.items,
                  subtotal: cartState.subtotal,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Gợi ý đồ uống chưa có trong giỏ, dựa trên danh mục global có tên/slug
  /// liên quan tới "nước"/"uống"/"drink".
  List<ProductModel> _drinkSuggestions(
    HomeState homeState,
    CartState cartState,
  ) {
    if (homeState is! HomeLoaded) return const [];

    bool isDrinkKeyword(String value) {
      final v = value.toLowerCase();
      return v.contains('nước') ||
          v.contains('nuoc') ||
          v.contains('uống') ||
          v.contains('uong') ||
          v.contains('drink');
    }

    final drinkCategoryIds = homeState.categories
        .where(
          (c) =>
              isDrinkKeyword(c.categoryName) || isDrinkKeyword(c.categorySlug),
        )
        .map((c) => c.id)
        .toSet();
    if (drinkCategoryIds.isEmpty) return const [];

    final cartProductIds = cartState.items.map((i) => i.productId).toSet();

    return homeState.products
        .where(
          (p) =>
              drinkCategoryIds.contains(p.categoryId) &&
              !cartProductIds.contains(p.id),
        )
        .take(8)
        .toList();
  }

  Future<bool> _showRemoveConfirm(BuildContext context, String productName) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await AppConfirmDialog.show(
      context,
      type: ConfirmDialogType.danger,
      title: l10n.cartRemoveConfirmTitle,
      description: l10n.cartRemoveConfirmMessage(productName),
      confirmTitle: l10n.cartRemoveConfirmBtn,
      cancelTitle: l10n.cartCancel,
    );
    return confirmed == true;
  }

  void _confirmClearCart(
    BuildContext context,
    CartCubit cubit,
    AppLocalizations l10n,
  ) {
    AppConfirmDialog.show(
      context,
      type: ConfirmDialogType.danger,
      title: l10n.cartClearAll,
      description: l10n.cartClearAllConfirm,
      confirmTitle: l10n.cartClearAll,
      cancelTitle: l10n.cartCancel,
    ).then((confirmed) {
      if (confirmed == true) {
        cubit.clearCart();
      }
    });
  }
}
