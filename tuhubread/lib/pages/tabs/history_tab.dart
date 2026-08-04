import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:tuhubread/l10n/app_localizations.dart';
import 'package:tuhubread/routes/routes.dart';
import '../../blocs/order/order_cubit.dart';
import '../../blocs/order/order_state.dart';
import '../../models/order.model.dart';
import '../../models/order_item.model.dart';
import '../../models/user.model.dart';
import '../../utils/currency_formatter.dart';

class HistoryTab extends StatelessWidget {
  final UserModel user;

  const HistoryTab({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return const _HistoryTabContent();
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
      l10n.historyFilterAll,
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

    return RefreshIndicator(
      onRefresh: () => context.read<OrderCubit>().loadOrders(),
      color: const Color(0xFFE67E22),
      child: BlocBuilder<OrderCubit, OrderState>(
        builder: (context, state) {
          if (state is OrderLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE67E22)),
            );
          }

          if (state is OrderFailure) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.7,
                alignment: Alignment.center,
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
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  alignment: Alignment.center,
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
                  child: filteredOrders.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.22),
                            Center(
                              child: Column(
                                children: [
                                  const Icon(Icons.receipt_long_rounded, size: 48, color: Color(0xFFBDC3C7)),
                                  const SizedBox(height: 12),
                                  Text(
                                    l10n.historyNoOrdersInStatus,
                                    style: const TextStyle(color: Color(0xFF7F8C8D), fontSize: 14),
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
                                                Expanded(
                                                  child: Text(
                                                    l10n.historyTotalLabel,
                                                    style: const TextStyle(
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
                                            if (order.orderStatus.toLowerCase() == 'completed') ...[
                                              const Divider(height: 24, color: Color(0xFFF1EAE1)),
                                              _buildReviewRow(context, l10n, order),
                                            ],
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
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  /// Khối đánh giá ở cuối thẻ đơn — chỉ hiện cho đơn đã hoàn thành. Đơn có
  /// nhiều sản phẩm thì đánh giá riêng từng sản phẩm — hiện "Đã đánh giá x/y
  /// sản phẩm" và cho bấm vào chọn sản phẩm chưa đánh giá.
  Widget _buildReviewRow(BuildContext context, AppLocalizations l10n, OrderModel order) {
    if (order.allReviewed) {
      return Row(
        children: [
          const Icon(Icons.star_rounded, color: Color(0xFFF1C40F), size: 16),
          const SizedBox(width: 6),
          Text(
            order.itemsCount > 1
                ? 'Đã đánh giá ${order.reviewedCount}/${order.itemsCount} sản phẩm'
                : l10n.historyReviewedLabel,
            style: const TextStyle(fontSize: 12, color: Color(0xFFBDC3C7), fontWeight: FontWeight.w600),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: () => _onReviewTap(context, l10n, order),
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          const Icon(Icons.star_border_rounded, color: Color(0xFFE67E22), size: 16),
          const SizedBox(width: 6),
          Text(
            order.itemsCount > 1
                ? '${l10n.historyReviewButton} (${order.reviewedCount}/${order.itemsCount})'
                : l10n.historyReviewButton,
            style: const TextStyle(fontSize: 12, color: Color(0xFFE67E22), fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// Đơn chỉ có 1 sản phẩm -> mở thẳng form đánh giá. Đơn nhiều sản phẩm ->
  /// hiện danh sách sản phẩm chưa đánh giá để khách chọn trước.
  Future<void> _onReviewTap(BuildContext context, AppLocalizations l10n, OrderModel order) async {
    final orderCubit = context.read<OrderCubit>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFFE67E22))),
    );
    final items = await orderCubit.fetchOrderItems(order.id);
    if (!context.mounted) return;
    Navigator.of(context).pop(); // đóng loading

    final unreviewed = items.where((i) => !i.isReviewed).toList();
    if (unreviewed.isEmpty) return;

    OrderItemModel? target = unreviewed.length == 1 ? unreviewed.first : null;
    if (target == null) {
      if (!context.mounted) return;
      target = await showModalBottomSheet<OrderItemModel>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _ProductPickerSheet(items: unreviewed),
      );
      if (target == null) return;
    }

    if (!context.mounted) return;
    await _showReviewSheet(context, l10n, order.id, target);
  }

  Future<void> _showReviewSheet(
    BuildContext context,
    AppLocalizations l10n,
    String orderId,
    OrderItemModel item,
  ) async {
    final orderCubit = context.read<OrderCubit>();
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => BlocProvider.value(
        value: orderCubit,
        child: _ReviewSheet(orderId: orderId, item: item, l10n: l10n),
      ),
    );
    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.historyReviewSuccess), backgroundColor: const Color(0xFF2ECC71)),
      );
    }
  }
}

/// Sheet chọn sản phẩm cần đánh giá khi đơn hàng có nhiều sản phẩm.
class _ProductPickerSheet extends StatelessWidget {
  final List<OrderItemModel> items;

  const _ProductPickerSheet({required this.items});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFDFBF7),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1EAE1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Chọn sản phẩm cần đánh giá',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (c, i) => const Divider(height: 1, color: Color(0xFFF1EAE1)),
                itemBuilder: (context, idx) {
                  final item = items[idx];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: item.productImage != null
                          ? Image.network(
                              item.productImage!,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(
                                width: 44,
                                height: 44,
                                color: const Color(0xFFF1EAE1),
                                child: const Icon(Icons.bakery_dining_rounded, color: Color(0xFFE67E22)),
                              ),
                            )
                          : Container(
                              width: 44,
                              height: 44,
                              color: const Color(0xFFF1EAE1),
                              child: const Icon(Icons.bakery_dining_rounded, color: Color(0xFFE67E22)),
                            ),
                    ),
                    title: Text(
                      item.productName,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                    ),
                    subtitle: Text(
                      item.variantName,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF7F8C8D)),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFBDC3C7)),
                    onTap: () => Navigator.of(context).pop(item),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewSheet extends StatefulWidget {
  final String orderId;
  final OrderItemModel item;
  final AppLocalizations l10n;

  const _ReviewSheet({required this.orderId, required this.item, required this.l10n});

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  static const _maxImages = 5;

  int _rating = 0;
  final _commentController = TextEditingController();
  bool _submitting = false;
  final List<XFile> _images = [];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickFromCamera() async {
    if (_images.length >= _maxImages) return;
    final picked = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 80);
    if (picked == null || !mounted) return;
    setState(() => _images.add(picked));
  }

  Future<void> _pickFromGallery() async {
    if (_images.length >= _maxImages) return;
    final remaining = _maxImages - _images.length;
    final picked = await ImagePicker().pickMultiImage(imageQuality: 80);
    if (picked.isEmpty || !mounted) return;
    setState(() => _images.addAll(picked.take(remaining)));
  }

  Future<void> _submit() async {
    final l10n = widget.l10n;
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.historyReviewRatingRequired), backgroundColor: const Color(0xFFE74C3C)),
      );
      return;
    }

    setState(() => _submitting = true);
    final success = await context.read<OrderCubit>().submitReview(
          widget.orderId,
          productId: widget.item.productId,
          rating: _rating,
          comment: _commentController.text,
          images: _images,
        );
    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.historyReviewError), backgroundColor: const Color(0xFFE74C3C)),
      );
    }
  }

  Widget _buildImagePicker() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (int i = 0; i < _images.length; i++)
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    File(_images[i].path),
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: -6,
                  right: -6,
                  child: GestureDetector(
                    onTap: () => setState(() => _images.removeAt(i)),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Color(0xFFE74C3C), shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                    ),
                  ),
                ),
              ],
            ),
          if (_images.length < _maxImages) ...[
            GestureDetector(
              onTap: _pickFromCamera,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF1EAE1)),
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Color(0xFFE67E22), size: 22),
              ),
            ),
            GestureDetector(
              onTap: _pickFromGallery,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF1EAE1)),
                ),
                child: const Icon(Icons.photo_library_rounded, color: Color(0xFFE67E22), size: 22),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFDFBF7),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1EAE1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.historyReviewSheetTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
            ),
            const SizedBox(height: 4),
            Text(
              widget.item.productName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Color(0xFF7F8C8D), fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final starIndex = i + 1;
                return IconButton(
                  onPressed: () => setState(() => _rating = starIndex),
                  icon: Icon(
                    starIndex <= _rating ? Icons.star_rounded : Icons.star_border_rounded,
                    color: const Color(0xFFF1C40F),
                    size: 34,
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: l10n.historyReviewCommentHint,
                hintStyle: const TextStyle(color: Color(0xFFBDC3C7), fontSize: 13),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFF1EAE1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFF1EAE1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE67E22)),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _buildImagePicker(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE67E22),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        l10n.historyReviewSubmitButton,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
