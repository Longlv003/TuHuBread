import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tuhubread/l10n/app_localizations.dart';
import '../../blocs/order/order_cubit.dart';
import '../../blocs/order/order_state.dart';
import '../../di.dart';
import '../../utils/currency_formatter.dart';

class TrackOrderPage extends StatelessWidget {
  const TrackOrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final orderId = Get.arguments as String;
    return BlocProvider<OrderCubit>(
      create: (context) => getIt<OrderCubit>()..loadOrderDetail(orderId),
      child: _TrackOrderContent(orderId: orderId),
    );
  }
}

class _TrackOrderContent extends StatefulWidget {
  final String orderId;
  const _TrackOrderContent({required this.orderId});

  @override
  State<_TrackOrderContent> createState() => _TrackOrderContentState();
}

class _TrackOrderContentState extends State<_TrackOrderContent> {


  String _getStatusDescription(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Đang chờ cửa hàng xác nhận đơn đặt hàng của bạn.';
      case 'confirmed':
        return 'Đơn hàng đã được xác nhận và đang chờ chuẩn bị.';
      case 'preparing':
        return 'Cửa hàng đang thực hiện làm bánh mì nóng hổi cho bạn.';
      case 'delivering':
        return 'Shipper đang trên đường giao bánh mì ngon lành đến địa chỉ của bạn.';
      case 'completed':
        return 'Đơn hàng đã giao thành công! Chúc bạn ăn ngon miệng.';
      default:
        return '';
    }
  }

  String _getPaymentMethodText(String method, AppLocalizations l10n) {
    switch (method.toLowerCase()) {
      case 'cash':
        return l10n.paymentMethodCash;
      case 'momo':
        return l10n.paymentMethodMomo;
      case 'bank':
        return l10n.paymentMethodBank;
      case 'vnpay':
        return l10n.paymentMethodVnpay;
      default:
        return method;
    }
  }

  String _getPaymentStatusText(String status, AppLocalizations l10n) {
    switch (status.toLowerCase()) {
      case 'unpaid':
        return l10n.paymentStatusUnpaid;
      case 'paid':
        return l10n.paymentStatusPaid;
      case 'refunded':
        return l10n.paymentStatusRefunded;
      default:
        return status;
    }
  }

  Widget _buildTimeline(String currentStatus, AppLocalizations l10n) {
    if (currentStatus.toLowerCase() == 'cancelled') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFCE8E6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF5B7B1)),
        ),
        child: Row(
          children: [
            const Icon(Icons.cancel_rounded, color: Color(0xFFC0392B), size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.orderStatusCancelled,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFFC0392B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Đơn hàng của bạn đã bị hủy và sẽ không được giao.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF7F8C8D)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final statuses = ['pending', 'confirmed', 'preparing', 'delivering', 'completed'];
    final titles = [
      l10n.orderStatusPending,
      l10n.orderStatusConfirmed,
      l10n.orderStatusPreparing,
      l10n.orderStatusDelivering,
      l10n.orderStatusCompleted
    ];
    final icons = [
      Icons.receipt_long_rounded,
      Icons.assignment_turned_in_rounded,
      Icons.soup_kitchen_rounded,
      Icons.local_shipping_rounded,
      Icons.check_circle_rounded
    ];

    int currentIndex = statuses.indexOf(currentStatus.toLowerCase());
    if (currentIndex == -1) currentIndex = 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1EAE1), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trạng thái đơn hàng',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 20),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: statuses.length,
            itemBuilder: (context, index) {
              final isCompleted = index <= currentIndex;
              final isCurrent = index == currentIndex;
              final color = isCompleted
                  ? const Color(0xFFE67E22)
                  : const Color(0xFFBDC3C7);

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? const Color(0xFFE67E22)
                              : isCompleted
                                  ? const Color(0xFFFFF0E0)
                                  : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: color,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          icons[index],
                          size: 16,
                          color: isCurrent ? Colors.white : color,
                        ),
                      ),
                      if (index < statuses.length - 1)
                        Container(
                          width: 2,
                          height: 36,
                          color: index < currentIndex
                              ? const Color(0xFFE67E22)
                              : const Color(0xFFF1EAE1),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Text(
                          titles[index],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isCurrent
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: isCurrent
                                ? const Color(0xFFE67E22)
                                : isCompleted
                                    ? const Color(0xFF2C3E50)
                                    : const Color(0xFFBDC3C7),
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(height: 4),
                          Text(
                            _getStatusDescription(currentStatus),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF7F8C8D),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _showCancelConfirmationDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n.cancelOrderConfirmTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
        ),
        content: Text(
          l10n.cancelOrderConfirmMessage,
          style: const TextStyle(color: Color(0xFF7F8C8D)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              l10n.no,
              style: const TextStyle(color: Color(0xFF7F8C8D), fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final orderCubit = context.read<OrderCubit>();
              final messenger = ScaffoldMessenger.of(context);
              final success = await orderCubit.cancelOrder(widget.orderId);
              if (success) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(l10n.cancelSuccess),
                    backgroundColor: const Color(0xFF27AE60),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text(
              l10n.yes,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
        title: Text(
          l10n.historyTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50), fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2C3E50), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFF1EAE1)),
        ),
      ),
      body: BlocBuilder<OrderCubit, OrderState>(
        builder: (context, state) {
          if (state is OrderLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE67E22)),
            );
          }

          if (state is OrderFailure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFE74C3C)),
                    const SizedBox(height: 12),
                    Text(
                      state.error,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF7F8C8D), fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<OrderCubit>().loadOrderDetail(widget.orderId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE67E22),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(l10n.retryButton),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is OrderDetailLoaded) {
            final order = state.order;
            final items = state.items;
            final isCancelling = state.isCancelling;
            final showCancelButton = order.orderStatus.toLowerCase() == 'pending';
            final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt.toLocal());

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Timeline
                        _buildTimeline(order.orderStatus, l10n),
                        const SizedBox(height: 16),

                        // 2. Order general info
                        Card(
                          color: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Color(0xFFF1EAE1), width: 1.5),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.receipt_long_rounded, color: Color(0xFFE67E22), size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${l10n.orderCodeLabel}${order.orderCode}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50), fontSize: 14),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24, color: Color(0xFFF1EAE1)),
                                _buildInfoRow(l10n.orderDateLabel, dateStr),
                                const SizedBox(height: 8),
                                _buildInfoRow(l10n.paymentMethodLabel, _getPaymentMethodText(order.paymentMethod, l10n)),
                                const SizedBox(height: 8),
                                _buildInfoRow(l10n.paymentStatusLabel, _getPaymentStatusText(order.paymentStatus, l10n)),
                                if (order.note != null && order.note!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  _buildInfoRow('Ghi chú: ', order.note!),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 3. Delivery address info
                        Card(
                          color: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Color(0xFFF1EAE1), width: 1.5),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_rounded, color: Color(0xFFE67E22), size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      l10n.addressLabel,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50), fontSize: 14),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24, color: Color(0xFFF1EAE1)),
                                Text(
                                  order.receiverName ?? 'Người nhận',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50), fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  order.receiverPhone ?? '',
                                  style: const TextStyle(color: Color(0xFF7F8C8D), fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  order.addressDetail ?? '',
                                  style: const TextStyle(color: Color(0xFF7F8C8D), fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 4. Items ordered
                        Card(
                          color: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Color(0xFFF1EAE1), width: 1.5),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.shopping_bag_rounded, color: Color(0xFFE67E22), size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Món đã chọn',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50), fontSize: 14),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24, color: Color(0xFFF1EAE1)),
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: items.length,
                                  separatorBuilder: (c, i) => const Divider(height: 24, color: Color(0xFFF1EAE1)),
                                  itemBuilder: (context, index) {
                                    final item = items[index];
                                    return Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Container(
                                            width: 48,
                                            height: 48,
                                            color: const Color(0xFFF1EAE1),
                                            child: item.productImage != null
                                                ? Image.network(
                                                    item.productImage!,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (c, e, s) => const Icon(
                                                      Icons.bakery_dining_rounded,
                                                      color: Color(0xFFE67E22),
                                                    ),
                                                  )
                                                : const Icon(
                                                    Icons.bakery_dining_rounded,
                                                    color: Color(0xFFE67E22),
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.productName,
                                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50), fontSize: 13),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Phân loại: ${item.variantName}',
                                                style: const TextStyle(color: Color(0xFF7F8C8D), fontSize: 11),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'x${item.quantity}',
                                                style: const TextStyle(color: Color(0xFF7F8C8D), fontSize: 11, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          CurrencyFormatter.formatVND(item.subtotal),
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50), fontSize: 13),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 5. Bill Summary
                        Card(
                          color: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Color(0xFFF1EAE1), width: 1.5),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                _buildBillRow(l10n.itemsTotalLabel, CurrencyFormatter.formatVND(order.itemsTotal)),
                                const SizedBox(height: 8),
                                _buildBillRow(l10n.deliveryFeeLabel, CurrencyFormatter.formatVND(order.deliveryFee)),
                                if (order.discountAmount > 0) ...[
                                  const SizedBox(height: 8),
                                  _buildBillRow(l10n.discountLabel, '-${CurrencyFormatter.formatVND(order.discountAmount)}', isDiscount: true),
                                ],
                                const Divider(height: 24, color: Color(0xFFF1EAE1)),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      l10n.totalAmountLabel,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50), fontSize: 14),
                                    ),
                                    Text(
                                      CurrencyFormatter.formatVND(order.totalAmount),
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD35400), fontSize: 16),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (showCancelButton)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Color(0xFFF1EAE1))),
                    ),
                    child: SafeArea(
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isCancelling
                              ? null
                              : () => _showCancelConfirmationDialog(context, l10n),
                          icon: isCancelling
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.cancel_outlined, color: Colors.white),
                          label: Text(
                            l10n.cancelOrderButton,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE74C3C),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF7F8C8D), fontSize: 12),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Color(0xFF2C3E50), fontSize: 12, fontWeight: FontWeight.bold),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildBillRow(String label, String value, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF7F8C8D), fontSize: 12),
        ),
        Text(
          value,
          style: TextStyle(
            color: isDiscount ? const Color(0xFF2ECC71) : const Color(0xFF2C3E50),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
