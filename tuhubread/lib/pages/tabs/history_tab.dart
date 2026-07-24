import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tuhubread/l10n/app_localizations.dart';
import 'package:tuhubread/routes/routes.dart';
import '../../blocs/order/order_cubit.dart';
import '../../blocs/order/order_state.dart';
import '../../di.dart';
import '../../models/user.model.dart';
import '../../utils/currency_formatter.dart';

class HistoryTab extends StatelessWidget {
  final UserModel user;

  const HistoryTab({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrderCubit>(
      create: (context) => getIt<OrderCubit>()..loadOrders(),
      child: const _HistoryTabContent(),
    );
  }
}

class _HistoryTabContent extends StatefulWidget {
  const _HistoryTabContent();

  @override
  State<_HistoryTabContent> createState() => _HistoryTabContentState();
}

class _HistoryTabContentState extends State<_HistoryTabContent> {
  String _activeFilter = 'all';

  String _getStatusText(String status, AppLocalizations l10n) {
    switch (status.toLowerCase()) {
      case 'pending':
        return l10n.orderStatusPending;
      case 'confirmed':
        return l10n.orderStatusConfirmed;
      case 'preparing':
        return l10n.orderStatusPreparing;
      case 'delivering':
        return l10n.orderStatusDelivering;
      case 'completed':
        return l10n.orderStatusCompleted;
      case 'cancelled':
        return l10n.orderStatusCancelled;
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFE67E22); // Cam
      case 'confirmed':
        return const Color(0xFF2980B9); // Xanh biển
      case 'preparing':
        return const Color(0xFF9B59B6); // Tím
      case 'delivering':
        return const Color(0xFF1ABC9C); // Xanh ngọc
      case 'completed':
        return const Color(0xFF2ECC71); // Xanh lá
      case 'cancelled':
        return const Color(0xFFE74C3C); // Đỏ
      default:
        return const Color(0xFF95A5A6); // Xám
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

  Widget _buildFilterChips(AppLocalizations l10n) {
    final filters = ['all', 'pending', 'confirmed', 'preparing', 'delivering', 'completed', 'cancelled'];
    final labels = [
      'Tất cả',
      l10n.orderStatusPending,
      l10n.orderStatusConfirmed,
      l10n.orderStatusPreparing,
      l10n.orderStatusDelivering,
      l10n.orderStatusCompleted,
      l10n.orderStatusCancelled
    ];

    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final label = labels[index];
          final isSelected = _activeFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _activeFilter = filter;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFE67E22) : const Color(0xFFF1EAE1).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFE67E22) : const Color(0xFFF1EAE1),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF2C3E50),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<OrderCubit, OrderState>(
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
                    onPressed: () => context.read<OrderCubit>().loadOrders(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE67E22),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(l10n.retryButton),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is OrderLoaded) {
          final orders = state.orders;

          if (orders.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.receipt_long_rounded, size: 64, color: Color(0xFFBDC3C7)),
                    const SizedBox(height: 16),
                    Text(
                      l10n.historyEmpty,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF7F8C8D)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.historyEmptySub,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFFBDC3C7), fontSize: 12),
                    ),
                  ],
                ),
              ),
            );
          }

          final filteredOrders = _activeFilter == 'all'
              ? orders
              : orders.where((o) => o.orderStatus.toLowerCase() == _activeFilter).toList();

          return Column(
            children: [
              const SizedBox(height: 12),
              _buildFilterChips(l10n),
              const SizedBox(height: 8),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => context.read<OrderCubit>().loadOrders(),
                  color: const Color(0xFFE67E22),
                  child: filteredOrders.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.22),
                            const Center(
                              child: Column(
                                children: [
                                  Icon(Icons.receipt_long_rounded, size: 48, color: Color(0xFFBDC3C7)),
                                  SizedBox(height: 12),
                                  Text(
                                    'Không có đơn hàng nào ở trạng thái này',
                                    style: TextStyle(color: Color(0xFF7F8C8D), fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16.0),
                          itemCount: filteredOrders.length,
                          itemBuilder: (context, index) {
                            final order = filteredOrders[index];
                            final color = _getStatusColor(order.orderStatus);
                            final statusText = _getStatusText(order.orderStatus, l10n);
                            final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt.toLocal());

                            return GestureDetector(
                              onTap: () {
                                final orderCubit = context.read<OrderCubit>();
                                Get.toNamed(Routes.trackOrderPage, arguments: order.id)?.then((_) {
                                  orderCubit.loadOrders();
                                });
                              },
                              child: Card(
                                color: Colors.white,
                                elevation: 0,
                                margin: const EdgeInsets.only(bottom: 16.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: const BorderSide(color: Color(0xFFF1EAE1), width: 1.5),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Shop logo
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1EAE1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: const Color(0xFFF1EAE1)),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: order.shopLogo != null
                                              ? Image.network(
                                                  order.shopLogo!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (c, e, s) => const Icon(
                                                    Icons.store_rounded,
                                                    color: Color(0xFFE67E22),
                                                  ),
                                                )
                                              : const Icon(
                                                  Icons.store_rounded,
                                                  color: Color(0xFFE67E22),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    order.shopName ?? 'TuHu Bread',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 15,
                                                      color: Color(0xFF2C3E50),
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: color.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: Text(
                                                    statusText,
                                                    style: TextStyle(
                                                      color: color,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              '${l10n.orderCodeLabel}${order.orderCode}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF7F8C8D),
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${l10n.orderDateLabel}$dateStr',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFFBDC3C7),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    l10n.paymentStatusLabel,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Color(0xFFBDC3C7),
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  _getPaymentStatusText(order.paymentStatus, l10n),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: order.paymentStatus.toLowerCase() == 'paid'
                                                        ? const Color(0xFF2ECC71)
                                                        : const Color(0xFFE74C3C),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                const Expanded(
                                                  child: Text(
                                                    'Tổng tiền:',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Color(0xFF7F8C8D),
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  CurrencyFormatter.formatVND(order.totalAmount),
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFFD35400),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
