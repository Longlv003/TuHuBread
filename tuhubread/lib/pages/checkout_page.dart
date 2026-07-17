import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart' as getx;
import 'package:tuhubread/l10n/app_localizations.dart';

import '../blocs/address/address_cubit.dart';
import '../blocs/address/address_state.dart';
import '../di.dart';
import '../models/address.model.dart';
import '../models/cart_item.model.dart';
import '../models/delivery_option.model.dart';
import '../utils/address_label.dart';
import '../utils/currency_formatter.dart';
import 'payment_method_page.dart';
import 'select_address_page.dart';

/// Màn hình thanh toán: chọn địa chỉ giao hàng + tùy chọn tốc độ giao hàng,
/// sau đó chuyển sang [PaymentMethodPage] để chọn phương thức thanh toán.
class CheckoutPage extends StatelessWidget {
  final List<CartItemModel> items;
  final double subtotal;

  const CheckoutPage({super.key, required this.items, required this.subtotal});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AddressCubit>(
      create: (_) => getIt<AddressCubit>()..loadMyAddresses(),
      child: _CheckoutContent(items: items, subtotal: subtotal),
    );
  }
}

class _CheckoutContent extends StatefulWidget {
  final List<CartItemModel> items;
  final double subtotal;

  const _CheckoutContent({required this.items, required this.subtotal});

  @override
  State<_CheckoutContent> createState() => _CheckoutContentState();
}

class _CheckoutContentState extends State<_CheckoutContent> {
  AddressModel? _selectedAddress;
  DeliveryOptionModel _selectedDelivery = DeliveryOptionModel.standard;
  bool _autoSelected = false;

  Future<void> _openSelectAddress(BuildContext context) async {
    final cubit = context.read<AddressCubit>();
    final result = await getx.Get.to<AddressModel>(
      () => BlocProvider.value(
        value: cubit,
        child: SelectAddressPage(selectedAddressId: _selectedAddress?.id),
      ),
      routeName: '/checkout/select-address',
      preventDuplicates: false,
    );
    if (result != null) {
      setState(() => _selectedAddress = result);
    }
  }

  void _continue(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.checkoutSelectAddressError),
          backgroundColor: const Color(0xFFE74C3C),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    getx.Get.to(
      () => PaymentMethodPage(
        items: widget.items,
        subtotal: widget.subtotal,
        address: _selectedAddress!,
        deliveryOption: _selectedDelivery,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.checkoutTitle,
          style: const TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF2C3E50),
          ),
          onPressed: () => getx.Get.back(),
        ),
      ),
      body: BlocConsumer<AddressCubit, AddressState>(
        listener: (context, state) {
          if (state is AddressLoaded && !_autoSelected) {
            _autoSelected = true;
            if (state.addresses.isNotEmpty) {
              final defaultAddress = state.addresses.firstWhere(
                (a) => a.isDefault,
                orElse: () => state.addresses.first,
              );
              setState(() => _selectedAddress = defaultAddress);
            }
          }
        },
        builder: (context, state) {
          if (state is AddressLoading || state is AddressInitial) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE67E22)),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _SectionCard(
                title: l10n.checkoutAddressSectionTitle,
                trailing: _selectedAddress != null
                    ? TextButton(
                        onPressed: () => _openSelectAddress(context),
                        child: Text(
                          l10n.checkoutChangeAddress,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFE67E22),
                          ),
                        ),
                      )
                    : null,
                child: _selectedAddress == null
                    ? _EmptyAddress(
                        l10n: l10n,
                        onAdd: () => _openSelectAddress(context),
                      )
                    : _AddressSummary(address: _selectedAddress!, l10n: l10n),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: l10n.checkoutDeliveryOptionSectionTitle,
                child: Column(
                  children: DeliveryOptionModel.all
                      .map(
                        (option) => _DeliveryOptionTile(
                          option: option,
                          selected: option.id == _selectedDelivery.id,
                          l10n: l10n,
                          onTap: () =>
                              setState(() => _selectedDelivery = option),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: l10n.checkoutOrderSectionTitle,
                child: Column(
                  children: widget.items
                      .map((item) => _OrderItemRow(item: item))
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: null,
                child: Column(
                  children: [
                    _PriceRow(
                      label: l10n.checkoutSubtotal,
                      value: widget.subtotal,
                    ),
                    const SizedBox(height: 8),
                    _PriceRow(
                      label: l10n.checkoutDeliveryFee,
                      value: _selectedDelivery.fee,
                    ),
                    const Divider(height: 20, color: Color(0xFFF1EAE1)),
                    _PriceRow(
                      label: l10n.checkoutTotal,
                      value: widget.subtotal + _selectedDelivery.fee,
                      emphasize: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _continue(context),
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
                    l10n.checkoutContinueButton,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String? title;
  final Widget? trailing;
  final Widget child;

  const _SectionCard({required this.title, this.trailing, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1EAE1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    title!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 8),
          ],
          child,
        ],
      ),
    );
  }
}

class _EmptyAddress extends StatelessWidget {
  final AppLocalizations l10n;
  final VoidCallback onAdd;

  const _EmptyAddress({required this.l10n, required this.onAdd});

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

class _AddressSummary extends StatelessWidget {
  final AddressModel address;
  final AppLocalizations l10n;

  const _AddressSummary({required this.address, required this.l10n});

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

class _DeliveryOptionTile extends StatelessWidget {
  final DeliveryOptionModel option;
  final bool selected;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  const _DeliveryOptionTile({
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

class _OrderItemRow extends StatelessWidget {
  final CartItemModel item;

  const _OrderItemRow({required this.item});

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

class _PriceRow extends StatelessWidget {
  final String label;
  final double value;
  final bool emphasize;

  const _PriceRow({
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
            fontWeight: FontWeight.bold,
            color: emphasize
                ? const Color(0xFFE74C3C)
                : const Color(0xFF2C3E50),
          ),
        ),
      ],
    );
  }
}
