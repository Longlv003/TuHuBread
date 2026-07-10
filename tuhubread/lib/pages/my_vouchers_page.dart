import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart' as getx;
import 'package:intl/intl.dart';
import 'package:tuhubread/l10n/app_localizations.dart';

import '../blocs/voucher/voucher_cubit.dart';
import '../blocs/voucher/voucher_state.dart';
import '../di.dart';
import '../models/voucher.model.dart';
import '../models/voucher_save.model.dart';
import '../utils/currency_formatter.dart';
import '../widgets/dashed_divider.dart';

class MyVouchersPage extends StatelessWidget {
  const MyVouchersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<VoucherCubit>(
      create: (_) => getIt<VoucherCubit>()..loadVouchers(),
      child: const _MyVouchersContent(),
    );
  }
}

class _MyVouchersContent extends StatefulWidget {
  const _MyVouchersContent();

  @override
  State<_MyVouchersContent> createState() => _MyVouchersContentState();
}

class _MyVouchersContentState extends State<_MyVouchersContent> {
  final _codeController = TextEditingController();
  bool _isRedeeming = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _redeem(AppLocalizations l10n) async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isRedeeming = true);
    final error = await context.read<VoucherCubit>().redeemByCode(code);
    if (!mounted) return;
    setState(() => _isRedeeming = false);

    if (error == null) {
      _codeController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.voucherRedeemSuccess), backgroundColor: const Color(0xFF27AE60)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: const Color(0xFFE74C3C)),
      );
    }
  }

  Future<void> _saveVoucher(AppLocalizations l10n, String voucherId) async {
    final error = await context.read<VoucherCubit>().saveVoucher(voucherId);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? l10n.voucherRedeemSuccess),
        backgroundColor: error == null ? const Color(0xFF27AE60) : const Color(0xFFE74C3C),
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
          l10n.myVouchersTitle,
          style: const TextStyle(color: Color(0xFF2C3E50), fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2C3E50)),
          onPressed: () => getx.Get.back(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: l10n.voucherEnterCodeHint,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFF1EAE1)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isRedeeming ? null : () => _redeem(l10n),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE67E22),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isRedeeming
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(l10n.voucherSaveButton, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<VoucherCubit, VoucherState>(
              builder: (context, state) {
                if (state is VoucherLoading || state is VoucherInitial) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFE67E22)),
                  );
                }

                if (state is VoucherFailure) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 54, color: Color(0xFFE74C3C)),
                          const SizedBox(height: 16),
                          Text(
                            state.error,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14, color: Color(0xFF7F8C8D)),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () => context.read<VoucherCubit>().loadVouchers(),
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

                final saves = state is VoucherLoaded ? state.savedVouchers : <VoucherSaveModel>[];
                final available = state is VoucherLoaded ? state.availableVouchers : <VoucherModel>[];

                return ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    if (saves.isEmpty)
                      _EmptyState(title: l10n.myVouchersEmptyTitle, subtitle: l10n.myVouchersEmptySubtitle)
                    else
                      ...saves.map((s) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _SavedVoucherCard(save: s, l10n: l10n),
                          )),
                    if (available.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        l10n.voucherAvailableSection,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                      ),
                      const SizedBox(height: 12),
                      ...available.map((v) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _AvailableVoucherCard(
                              voucher: v,
                              l10n: l10n,
                              onSave: () => _saveVoucher(l10n, v.id),
                            ),
                          )),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyState({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32.0),
      child: Column(
        children: [
          const Icon(Icons.confirmation_number_outlined, size: 64, color: Color(0xFFBDC3C7)),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF7F8C8D)),
          ),
        ],
      ),
    );
  }
}

/// "Vỏ" thẻ voucher dạng ticket (khối trái màu + đường kẻ đứt nét + khối phải
/// trắng) — dùng chung cho cả voucher đã lưu và voucher có thể lưu.
class _VoucherTicketShell extends StatelessWidget {
  final String discountLabel;
  final String discountCaption;
  final bool dimmed;
  final Widget rightContent;

  const _VoucherTicketShell({
    required this.discountLabel,
    required this.discountCaption,
    required this.rightContent,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = dimmed ? const Color(0xFFBDC3C7) : const Color(0xFFE67E22);

    return Opacity(
      opacity: dimmed ? 0.55 : 1.0,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 88,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    discountLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    discountCaption,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            VerticalDashedDivider(color: accentColor),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: rightContent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _discountLabelFor(VoucherModel voucher, AppLocalizations l10n) {
  switch (voucher.discountType) {
    case 'percent':
      return '-${voucher.discountValue.toInt()}%';
    case 'free_shipping':
      return l10n.voucherFreeShipLabel;
    default:
      final value = voucher.discountValue;
      return value >= 1000 ? '-${(value / 1000).toStringAsFixed(0)}K' : '-${value.toInt()}đ';
  }
}

class _SavedVoucherCard extends StatelessWidget {
  final VoucherSaveModel save;
  final AppLocalizations l10n;

  const _SavedVoucherCard({required this.save, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final voucher = save.voucher;
    final dateFormat = DateFormat('dd/MM/yyyy');
    final isDimmed = save.isUsed || save.isExpired;

    final String statusLabel;
    if (save.isUsed) {
      statusLabel = l10n.myVouchersUsedLabel;
    } else if (save.isExpired) {
      statusLabel = l10n.myVouchersExpiredLabel;
    } else {
      statusLabel = '';
    }

    return _VoucherTicketShell(
      discountLabel: voucher == null ? '' : _discountLabelFor(voucher, l10n),
      discountCaption: l10n.voucherDiscountLabel,
      dimmed: isDimmed,
      rightContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  voucher?.voucherName ?? save.voucherCode,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (statusLabel.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1EAE1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF7F8C8D)),
                  ),
                ),
            ],
          ),
          if (voucher != null) ...[
            const SizedBox(height: 4),
            Text(
              l10n.voucherMinOrder(CurrencyFormatter.formatVND(voucher.minOrderAmount)),
              style: const TextStyle(fontSize: 11, color: Color(0xFF7F8C8D)),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            l10n.myVouchersExpiresOn(dateFormat.format(save.expiresAt)),
            style: const TextStyle(fontSize: 11, color: Color(0xFF7F8C8D)),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: isDimmed
                  ? null
                  : () => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.voucherUseAtCheckoutMsg)),
                      ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: isDimmed ? const Color(0xFFBDC3C7) : const Color(0xFFE67E22)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(
                l10n.voucherUseNowButton,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDimmed ? const Color(0xFFBDC3C7) : const Color(0xFFE67E22),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailableVoucherCard extends StatelessWidget {
  final VoucherModel voucher;
  final AppLocalizations l10n;
  final VoidCallback onSave;

  const _AvailableVoucherCard({required this.voucher, required this.l10n, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return _VoucherTicketShell(
      discountLabel: _discountLabelFor(voucher, l10n),
      discountCaption: l10n.voucherDiscountLabel,
      rightContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            voucher.voucherName,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.voucherMinOrder(CurrencyFormatter.formatVND(voucher.minOrderAmount)),
            style: const TextStyle(fontSize: 11, color: Color(0xFF7F8C8D)),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.myVouchersExpiresOn(dateFormat.format(voucher.endDate)),
            style: const TextStyle(fontSize: 11, color: Color(0xFF7F8C8D)),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE67E22),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              child: Text(
                l10n.voucherSaveButton,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
