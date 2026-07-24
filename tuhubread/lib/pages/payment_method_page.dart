import 'package:flutter/material.dart';
import 'package:get/get.dart' as getx;
import 'package:tuhubread/l10n/app_localizations.dart';

import '../blocs/cart/cart_cubit.dart';
import '../core/result.dart';
import '../di.dart';
import '../models/address.model.dart';
import '../models/cart_item.model.dart';
import '../models/delivery_option.model.dart';
import '../models/order_result.model.dart';
import '../repositories/order_repository.dart';
import '../utils/currency_formatter.dart';
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
  static const momo = _PaymentMethod(
    id: 'momo',
    icon: Icons.account_balance_wallet_rounded,
    color: Color(0xFFD82D8B),
  );
  static const zalopay = _PaymentMethod(
    id: 'zalopay',
    icon: Icons.account_balance_wallet_rounded,
    color: Color(0xFF0068FF),
  );

  static const all = [cash, vnpay, momo, zalopay];
}

/// Màn hình chọn phương thức thanh toán và xác nhận đặt hàng.
class PaymentMethodPage extends StatefulWidget {
  final List<CartItemModel> items;
  final double subtotal;
  final AddressModel address;
  final DeliveryOptionModel deliveryOption;

  const PaymentMethodPage({
    super.key,
    required this.items,
    required this.subtotal,
    required this.address,
    required this.deliveryOption,
  });

  @override
  State<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends State<PaymentMethodPage> {
  _PaymentMethod _selectedMethod = _PaymentMethod.cash;
  final _noteController = TextEditingController();
  bool _isPlacingOrder = false;

  double get _total => widget.subtotal + widget.deliveryOption.fee;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String _methodLabel(AppLocalizations l10n, String id) {
    switch (id) {
      case 'vnpay':
        return l10n.paymentMethodVnpay;
      case 'momo':
        return l10n.paymentMethodMomo;
      case 'zalopay':
        return l10n.paymentMethodZalopay;
      default:
        return l10n.paymentMethodCash;
    }
  }

  Future<void> _placeOrder() async {
    if (_isPlacingOrder) return;
    setState(() => _isPlacingOrder = true);

    final noteText = _noteController.text.trim().isEmpty
        ? null
        : _noteController.text.trim();

    final l10n = AppLocalizations.of(context)!;

    if (_selectedMethod.id == 'vnpay') {
      // 1. Tạo thanh toán VNPay (validate trên server và lấy paymentUrl)
      final res = await getIt<OrderRepository>().createVnpayPayment(
        addressId: widget.address.id,
        deliveryOption: widget.deliveryOption.id,
        note: noteText,
      );

      if (!mounted) return;
      setState(() => _isPlacingOrder = false);

      if (res is Success<OrderResultModel>) {
        final paymentUrl = res.data.paymentUrl;
        if (paymentUrl != null && paymentUrl.isNotEmpty) {
          // 2. Mở WebView để thanh toán
          final paymentResult = await getx.Get.to<bool>(
            () => VnPayPaymentPage(paymentUrl: paymentUrl),
          );

          if (!mounted) return;

          if (paymentResult == true) {
            // Thanh toán thành công
            getIt<CartCubit>().clearCart();
            await _showSuccessDialog(l10n, res.data);
          } else {
            // Thanh toán thất bại hoặc hủy
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Thanh toán VNPay thất bại hoặc đã bị hủy'),
                backgroundColor: Color(0xFFE74C3C),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể khởi tạo liên kết thanh toán VNPay'),
              backgroundColor: Color(0xFFE74C3C),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else if (res is Failure<OrderResultModel>) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message),
            backgroundColor: const Color(0xFFE74C3C),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      // 2. Thanh toán COD như bình thường
      final res = await getIt<OrderRepository>().createOrder(
        addressId: widget.address.id,
        deliveryOption: widget.deliveryOption.id,
        paymentMethod: _selectedMethod.id,
        items: widget.items,
        note: noteText,
      );

      if (!mounted) return;
      setState(() => _isPlacingOrder = false);

      if (res is Success<OrderResultModel>) {
        getIt<CartCubit>().clearCart();
        await _showSuccessDialog(l10n, res.data);
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
  }

  Future<void> _showSuccessDialog(
    AppLocalizations l10n,
    OrderResultModel result,
  ) {
    final code = result.orderCodes.isNotEmpty
        ? result.orderCodes.join(', ')
        : '';
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
          l10n.paymentOrderSuccessMessage(code),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.paymentTitle,
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(
            l10n.paymentMethodSectionTitle,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 10),
          ..._PaymentMethod.all.map(
            (method) => _MethodTile(
              method: method,
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
          const SizedBox(height: 16),
          Text(
            l10n.paymentOrderNoteLabel,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
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
        ],
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.checkoutTotal,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF7F8C8D),
                    ),
                  ),
                  Text(
                    CurrencyFormatter.formatVND(_total),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE74C3C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isPlacingOrder ? null : _placeOrder,
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
                          l10n.paymentPlaceOrderButton,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  final _PaymentMethod method;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MethodTile({
    required this.method,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: method.color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(method.icon, color: method.color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: 18,
              color: selected
                  ? const Color(0xFFE67E22)
                  : const Color(0xFFBDC3C7),
            ),
          ],
        ),
      ),
    );
  }
}
