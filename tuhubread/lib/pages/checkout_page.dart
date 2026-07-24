import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart' as getx;
import 'package:tuhubread/l10n/app_localizations.dart';

import '../blocs/address/address_cubit.dart';
import '../blocs/address/address_state.dart';
import '../blocs/cart/cart_cubit.dart';
import '../blocs/payment/payment_cubit.dart';
import '../blocs/payment/payment_state.dart';
import '../blocs/voucher/voucher_cubit.dart';
import '../blocs/voucher/voucher_state.dart';
import '../core/result.dart';
import '../di.dart';
import '../models/address.model.dart';
import '../models/cart_item.model.dart';
import '../models/delivery_option.model.dart';
import '../models/order_result.model.dart';
import '../models/payment_verify_result.model.dart';
import '../models/voucher_save.model.dart';
import '../repositories/order_repository.dart';

import '../utils/currency_formatter.dart';
import '../widgets/checkout/checkout_address_section.dart';
import '../widgets/checkout/checkout_delivery_option_tile.dart';
import '../widgets/checkout/checkout_order_item_row.dart';
import '../widgets/checkout/checkout_payment_method_tile.dart';
import '../widgets/checkout/checkout_price_row.dart';
import '../widgets/checkout/checkout_section_card.dart';
import 'select_address_page.dart';
import 'vnpay_payment_page.dart';

class _PaymentMethod {
  final String id;
  final IconData icon;
  final Color color;

  const _PaymentMethod({
    required this.id,
    required this.icon,
    required this.color,
  });

  static const cash = _PaymentMethod(
    id: 'cash',
    icon: Icons.payments_rounded,
    color: Color(0xFF27AE60),
  );
  static const vnpay = _PaymentMethod(
    id: 'vnpay',
    icon: Icons.account_balance_rounded,
    color: Color(0xFF0068FF),
  );

  static const all = [cash, vnpay];
}

/// Màn hình thanh toán: chọn địa chỉ giao hàng, tùy chọn tốc độ giao hàng,
/// phương thức thanh toán, và tiến hành đặt hàng.
class CheckoutPage extends StatelessWidget {
  final List<CartItemModel> items;
  final double subtotal;

  const CheckoutPage({super.key, required this.items, required this.subtotal});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AddressCubit>(
          create: (_) => getIt<AddressCubit>()..loadMyAddresses(),
        ),
        BlocProvider<VoucherCubit>(
          create: (_) => getIt<VoucherCubit>()..loadVouchers(),
        ),
        BlocProvider<PaymentCubit>(
          create: (_) => getIt<PaymentCubit>(),
        ),
      ],
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
  _PaymentMethod _selectedMethod = _PaymentMethod.cash;
  VoucherSaveModel? _selectedVoucher;
  final _noteController = TextEditingController();
  bool _autoSelected = false;
  bool _isPlacingOrder = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  double _calculateVoucherDiscount(VoucherSaveModel? save) {
    if (save == null || save.voucher == null) return 0.0;
    final v = save.voucher!;
    if (widget.subtotal < v.minOrderAmount) return 0.0;

    if (v.discountType == 'free_shipping') {
      return _selectedDelivery.fee;
    } else if (v.discountType == 'percent') {
      double discount = widget.subtotal * (v.discountValue / 100);
      if (v.maxDiscountAmount != null && discount > v.maxDiscountAmount!) {
        discount = v.maxDiscountAmount!;
      }
      return discount;
    } else if (v.discountType == 'amount') {
      return v.discountValue;
    }
    return 0.0;
  }

  Future<void> _openSelectVoucher(
    BuildContext context,
    List<VoucherSaveModel> savedVouchers,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    final eligibleVouchers = savedVouchers.where((v) {
      if (!v.isAvailable || v.voucher == null) return false;
      return widget.subtotal >= v.voucher!.minOrderAmount;
    }).toList();

    final result = await showModalBottomSheet<VoucherSaveModel?>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.myVouchersTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF7F8C8D)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (eligibleVouchers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40.0),
                child: Center(
                  child: Text(
                    l10n.checkoutVoucherNoEligible,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF7F8C8D),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: eligibleVouchers.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final item = eligibleVouchers[idx];
                    final voucher = item.voucher!;
                    final isSelected = _selectedVoucher?.id == item.id;

                    String discountDesc = "";
                    if (voucher.discountType == "percent") {
                      if (voucher.maxDiscountAmount != null) {
                        discountDesc = l10n.checkoutVoucherDiscountPercentMax(
                          voucher.discountValue,
                          CurrencyFormatter.formatVND(voucher.maxDiscountAmount!),
                        );
                      } else {
                        discountDesc = l10n.checkoutVoucherDiscountPercent(voucher.discountValue);
                      }
                    } else if (voucher.discountType == "amount") {
                      discountDesc = l10n.checkoutVoucherDiscountAmount(
                        CurrencyFormatter.formatVND(voucher.discountValue),
                      );
                    } else if (voucher.discountType == "free_shipping") {
                      discountDesc = l10n.checkoutVoucherFreeShipping;
                    }

                    return InkWell(
                      onTap: () => Navigator.pop(context, item),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFFDF0E5)
                              : const Color(0xFFFAFAFA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFE67E22)
                                : const Color(0xFFF1EAE1),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE67E22).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.local_offer_rounded,
                                color: Color(0xFFE67E22),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    voucher.voucherName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    discountDesc,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFE67E22),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    l10n.checkoutVoucherMinOrder(CurrencyFormatter.formatVND(voucher.minOrderAmount)),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF7F8C8D),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              isSelected
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined,
                              color: const Color(0xFFE67E22),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 10),
            if (_selectedVoucher != null)
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: Text(
                    l10n.checkoutVoucherDoNotUse,
                    style: const TextStyle(
                      color: Color(0xFFE74C3C),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (result != null || _selectedVoucher != null) {
      setState(() => _selectedVoucher = result);
    }
  }

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

  String _methodLabel(AppLocalizations l10n, String id) {
    switch (id) {
      case 'vnpay':
        return l10n.paymentMethodVnpay;
      default:
        return l10n.paymentMethodCash;
    }
  }

  Future<void> _placeOrder(BuildContext context) async {
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

    if (_isPlacingOrder) return;
    setState(() => _isPlacingOrder = true);

    final noteText = _noteController.text.trim().isEmpty
        ? null
        : _noteController.text.trim();
    final voucherCode = _selectedVoucher?.voucherCode;

    // ── Thanh toán VNPay ─────────────────────────────────────────────────────
    if (_selectedMethod.id == 'vnpay') {
      await _placeVnpayOrder(
        context: context,
        l10n: l10n,
        noteText: noteText,
        voucherCode: voucherCode,
      );
      return;
    }

    // ── Thanh toán COD / các phương thức khác ────────────────────────────────
    final res = await getIt<OrderRepository>().createOrder(
      addressId: _selectedAddress!.id,
      deliveryOption: _selectedDelivery.id,
      paymentMethod: _selectedMethod.id,
      items: widget.items,
      note: noteText,
      voucherCode: voucherCode,
    );

    if (!mounted) return;
    setState(() => _isPlacingOrder = false);

    if (res is Success<OrderResultModel>) {
      getIt<CartCubit>().clearCart();
      await _showSuccessDialog(context, l10n, res.data);
    } else if (res is Failure<OrderResultModel>) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message),
          backgroundColor: const Color(0xFFE74C3C),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Luồng VNPay:
  ///  1. PaymentCubit.initiateVnpayPayment() → nhận paymentUrl
  ///  2. Mở VnPayPaymentPage (WebView)
  ///  3. WebView đóng → nhận VnPayResult với txnRef
  ///  4. PaymentCubit.verifyAfterWebView(txnRef) → kết quả cuối cùng
  Future<void> _placeVnpayOrder({
    required BuildContext context,
    required AppLocalizations l10n,
    String? noteText,
    String? voucherCode,
  }) async {
    final paymentCubit = context.read<PaymentCubit>();

    // Bước 1: Gọi backend tạo session + URL
    await paymentCubit.initiateVnpayPayment(
      addressId: _selectedAddress!.id,
      deliveryOption: _selectedDelivery.id,
      voucherCode: voucherCode,
      note: noteText,
    );

    if (!mounted) return;
    setState(() => _isPlacingOrder = false);

    final currentState = paymentCubit.state;
    if (currentState is! PaymentUrlReady) {
      // Lỗi khi tạo URL
      final msg = currentState is PaymentError
          ? currentState.message
          : 'Không thể tạo link thanh toán';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: const Color(0xFFE74C3C),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Bước 2: Mở WebView
    final vnPayResult = await getx.Get.to<VnPayResult>(
      () => VnPayPaymentPage(paymentUrl: currentState.paymentUrl),
      routeName: '/checkout/vnpay-payment',
      preventDuplicates: false,
    );

    if (!mounted) return;

    // Người dùng đóng WebView bằng nút X (không có txnRef)
    if (vnPayResult == null || vnPayResult.txnRef == null) {
      await _showFailedDialog(context, l10n);
      return;
    }

    // Bước 3: Verify kết quả từ backend
    setState(() => _isPlacingOrder = true);
    await paymentCubit.verifyAfterWebView(txnRef: vnPayResult.txnRef!);
    if (!mounted) return;
    setState(() => _isPlacingOrder = false);

    final verifyState = paymentCubit.state;
    if (verifyState is PaymentSuccess) {
      // Làm sạch giỏ hàng local
      getIt<CartCubit>().clearCart();
      await _showSuccessFromVerify(context, l10n, verifyState.result);
    } else {
      await _showFailedDialog(context, l10n);
    }
  }

  Future<void> _showSuccessDialog(
    BuildContext context,
    AppLocalizations l10n,
    OrderResultModel result,
  ) {
    final code = result.orderCodes.isNotEmpty
        ? result.orderCodes.join(', ')
        : '';
    return _showSuccessAlertDialog(context, l10n, code);
  }

  Future<void> _showSuccessFromVerify(
    BuildContext context,
    AppLocalizations l10n,
    PaymentVerifyResult result,
  ) {
    final code = result.orderCodes.isNotEmpty
        ? result.orderCodes.join(', ')
        : '';
    return _showSuccessAlertDialog(context, l10n, code);
  }

  Future<void> _showSuccessAlertDialog(
    BuildContext context,
    AppLocalizations l10n,
    String orderCode,
  ) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(
          Icons.check_circle_rounded,
          color: Color(0xFF27AE60),
          size: 48,
        ),
        title: Text(l10n.paymentOrderSuccessTitle, textAlign: TextAlign.center),
        content: Text(
          l10n.paymentOrderSuccessMessage(orderCode),
          textAlign: TextAlign.center,
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => getx.Get.until((route) => route.isFirst),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE67E22),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(l10n.paymentBackToHome),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFailedDialog(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(
          Icons.error_outline_rounded,
          color: Color(0xFFE74C3C),
          size: 48,
        ),
        title: Text(l10n.paymentOrderFailed, textAlign: TextAlign.center),
        content: const Text(
          "Thanh toán qua VNPAY không thành công. Bạn có thể kiểm tra lại trạng thái đơn hàng trong lịch sử đặt hàng.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Color(0xFF7F8C8D)),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => getx.Get.until((route) => route.isFirst),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE74C3C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(l10n.paymentBackToHome),
            ),
          ),
        ],
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
              // 1. Địa chỉ
              CheckoutSectionCard(
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
                    ? CheckoutEmptyAddress(
                        l10n: l10n,
                        onAdd: () => _openSelectAddress(context),
                      )
                    : CheckoutAddressSummary(
                        address: _selectedAddress!,
                        l10n: l10n,
                      ),
              ),
              const SizedBox(height: 16),

              // 2. Các sản phẩm
              CheckoutSectionCard(
                title: l10n.checkoutOrderSectionTitle,
                child: Column(
                  children: widget.items
                      .map((item) => CheckoutOrderItemRow(item: item))
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),

              // 3. Tùy chọn giao hàng
              CheckoutSectionCard(
                title: l10n.checkoutDeliveryOptionSectionTitle,
                child: Column(
                  children: DeliveryOptionModel.all
                      .map(
                        (option) => CheckoutDeliveryOptionTile(
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

              // 4.5. Chọn Voucher (hiển thị trước Phương thức thanh toán)
              BlocBuilder<VoucherCubit, VoucherState>(
                builder: (context, voucherState) {
                  List<VoucherSaveModel> saved = [];
                  if (voucherState is VoucherLoaded) {
                    saved = voucherState.savedVouchers;
                  }

                  final eligibleCount = saved.where((v) {
                    return v.isAvailable &&
                        v.voucher != null &&
                        widget.subtotal >= v.voucher!.minOrderAmount;
                  }).length;

                  return CheckoutSectionCard(
                    title: l10n.checkoutVoucherSectionTitle,
                    trailing: TextButton(
                      onPressed: () => _openSelectVoucher(context, saved),
                      child: Text(
                        _selectedVoucher != null ? l10n.checkoutVoucherChange : l10n.checkoutVoucherSelect,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFE67E22),
                        ),
                      ),
                    ),
                    child: _selectedVoucher == null
                        ? InkWell(
                            onTap: () => _openSelectVoucher(context, saved),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.local_offer_outlined,
                                  color: Color(0xFFE67E22),
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    eligibleCount > 0
                                        ? l10n.checkoutVoucherEligibleCount(eligibleCount)
                                        : l10n.checkoutVoucherChoosePlaceholder,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF7F8C8D),
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 14,
                                  color: Color(0xFFBDC3C7),
                                ),
                              ],
                            ),
                          )
                        : Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFE67E22,
                                  ).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.local_offer_rounded,
                                  color: Color(0xFFE67E22),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedVoucher!.voucher!.voucherName,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2C3E50),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      l10n.checkoutVoucherApplied(
                                        CurrencyFormatter.formatVND(_calculateVoucherDiscount(_selectedVoucher)),
                                      ),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF27AE60),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // 4. Chọn phương thức thanh toán
              CheckoutSectionCard(
                title: l10n.paymentMethodSectionTitle,
                child: Column(
                  children: [
                    ..._PaymentMethod.all.map(
                      (method) => CheckoutPaymentMethodTile(
                        icon: method.icon,
                        color: method.color,
                        label: _methodLabel(l10n, method.id),
                        selected: method.id == _selectedMethod.id,
                        onTap: () => setState(() => _selectedMethod = method),
                      ),
                    ),
                    if (_selectedMethod.id != 'cash' && _selectedMethod.id != 'vnpay') ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDF0E5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 18,
                              color: Color(0xFFE67E22),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.paymentMethodOnlineNote,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF7F8C8D),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 5. Ghi chú
              CheckoutSectionCard(
                title: l10n.paymentOrderNoteLabel,
                child: TextField(
                  controller: _noteController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: l10n.paymentOrderNoteHint,
                    hintStyle: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFBDC3C7),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFF1EAE1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFF1EAE1)),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Container(
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
          child: Builder(
            builder: (context) {
              final discount = _calculateVoucherDiscount(_selectedVoucher);
              final total = widget.subtotal - discount + _selectedDelivery.fee;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckoutPriceRow(
                    label: l10n.checkoutSubtotal,
                    value: widget.subtotal,
                  ),
                  if (discount > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.discountLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        Text(
                          "-${CurrencyFormatter.formatVND(discount)}",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF27AE60),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  CheckoutPriceRow(
                    label: l10n.checkoutDeliveryFee,
                    value: _selectedDelivery.fee,
                  ),
                  const Divider(height: 16, color: Color(0xFFF1EAE1)),
                  CheckoutPriceRow(
                    label: l10n.checkoutTotal,
                    value: total < 0 ? 0.0 : total,
                    emphasize: true,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isPlacingOrder
                          ? null
                          : () => _placeOrder(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE67E22),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      child: _isPlacingOrder
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              l10n.cartCheckout,
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
        ),
      ),
    );
  }
}
