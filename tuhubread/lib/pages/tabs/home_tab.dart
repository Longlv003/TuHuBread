import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart' as getx;
import 'package:tuhubread/l10n/app_localizations.dart';

import '../../blocs/home/home_cubit.dart';
import '../../blocs/home/home_state.dart';
import '../../models/shop.model.dart';
import '../../models/user.model.dart';
import '../../models/voucher.model.dart';
import '../../routes/routes.dart';
import '../../utils/currency_formatter.dart';

class HomeTab extends StatelessWidget {
  final UserModel user;

  /// Gọi mỗi khi hướng cuộn thay đổi — true = đang cuộn xuống (nên ẩn tab
  /// bar để nhường diện tích), false = đang cuộn lên/về đầu trang (nên hiện
  /// lại). Dùng để làm hiệu ứng tab bar tự ẩn/hiện kiểu Grab.
  final ValueChanged<bool>? onScrollHide;

  const HomeTab({super.key, required this.user, this.onScrollHide});

  @override
  Widget build(BuildContext context) {
    return _HomeTabContent(user: user, onScrollHide: onScrollHide);
  }
}

class _HomeTabContent extends StatefulWidget {
  final UserModel user;
  final ValueChanged<bool>? onScrollHide;

  const _HomeTabContent({required this.user, this.onScrollHide});

  @override
  State<_HomeTabContent> createState() => _HomeTabContentState();
}

class _HomeTabContentState extends State<_HomeTabContent> {
  // Countdown timer — tick mỗi giây để cập nhật UI
  Timer? _countdownTimer;
  DateTime _now = DateTime.now();

  // PageController cho Voucher Slider và Timer tự động chạy
  final PageController _voucherPageController = PageController();
  Timer? _voucherSliderTimer;

  // Set tracking voucher IDs user đã save (mock local state)
  final Set<String> _savedVoucherIds = {};

  // Theo dõi hướng cuộn để tự ẩn/hiện tab bar (kiểu Grab)
  final ScrollController _scrollController = ScrollController();
  double _lastScrollOffset = 0;
  bool _navHidden = false;

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });

    // Auto-scroll Voucher Slide mỗi 3 giây
    _voucherSliderTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final homeState = context.read<HomeCubit>().state;
      if (homeState is! HomeLoaded) return;
      final visibleVouchers = _getVisibleVouchers(homeState);
      if (visibleVouchers.isEmpty) return;
      if (_voucherPageController.hasClients) {
        int nextPage = _voucherPageController.page!.toInt() + 1;
        if (nextPage >= visibleVouchers.length) {
          nextPage = 0;
        }
        _voucherPageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });

    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    final offset = _scrollController.offset;
    final delta = offset - _lastScrollOffset;
    _lastScrollOffset = offset;

    // Bỏ qua rung lắc nhỏ (đầu ngón tay run, hiệu ứng bounce...) — chỉ phản
    // ứng khi kéo đủ xa để chắc chắn là người dùng thật sự đang cuộn.
    if (delta.abs() < 6) return;

    final shouldHide = delta > 0 && offset > 40;
    if (shouldHide != _navHidden) {
      _navHidden = shouldHide;
      widget.onScrollHide?.call(shouldHide);
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _voucherSliderTimer?.cancel();
    _voucherPageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ─────────── COMPUTED PROPERTIES / HELPERS ───────────

  /// Vouchers hiển thị trên UI — trả về rỗng khi:
  /// 1. API lỗi hoặc chưa có dữ liệu (vouchers empty)
  /// 2. User đã save tất cả voucher còn lại
  /// 3. Tất cả voucher đã hết mã (claimedCount >= claimLimit)
  /// → build() dùng .isNotEmpty để ẩn/hiện toàn bộ section Voucher
  List<VoucherModel> _getVisibleVouchers(HomeLoaded state) {
    return state.vouchers.where((v) {
      final isSaved = _savedVoucherIds.contains(v.id);
      final isFull = v.claimLimit != null && v.claimedCount >= v.claimLimit!;
      return !isSaved && !isFull;
    }).toList();
  }

  // ─────────── BUILD ───────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state is HomeLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFE67E22)),
          );
        }

        if (state is HomeFailure) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: Color(0xFFE74C3C),
                ),
                const SizedBox(height: 12),
                Text(
                  state.error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF7F8C8D),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<HomeCubit>().refresh(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE67E22),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(l10n.retryButton),
                ),
              ],
            ),
          );
        }

        if (state is HomeLoaded) {
          final visibleVouchers = _getVisibleVouchers(state);

          return RefreshIndicator(
            onRefresh: () => context.read<HomeCubit>().refresh(),
            color: const Color(0xFFE67E22),
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Voucher Slider
                  if (visibleVouchers.isNotEmpty) ...[
                    _buildVoucherSlider(l10n, visibleVouchers),
                    const SizedBox(height: 24),
                  ],

                  // 2. Danh sách Shop
                  _buildShopsSection(state.shops, l10n),
                ],
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  // ─────────── SHOP SELECTOR ───────────

  Widget _buildShopsSection(List<ShopModel> shops, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE67E22).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: Color(0xFFE67E22),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                "Cửa hàng gần bạn",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                "(${shops.length})",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFBDC3C7),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (shops.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1EAE1)),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.store_mall_directory_outlined,
                    size: 40,
                    color: Color(0xFFBDC3C7),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Chưa có cửa hàng nào gần bạn",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF7F8C8D),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: shops.length,
            itemBuilder: (context, idx) {
              final shop = shops[idx];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFF1EAE1),
                    width: 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 14,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      getx.Get.toNamed(
                        Routes.shopHomePage,
                        arguments: {
                          'shop': shop,
                          'homeCubit': context.read<HomeCubit>(),
                        },
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              shop.logo,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(
                                width: 64,
                                height: 64,
                                color: const Color(0xFFF1EAE1),
                                child: const Icon(
                                  Icons.store_rounded,
                                  color: Color(0xFFE67E22),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  shop.shopName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2C3E50),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF6E5),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.star_rounded,
                                            color: Color(0xFFF1C40F),
                                            size: 13,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            shop.rating == null
                                                ? "Mới"
                                                : "${shop.rating}",
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF7F8C8D),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (shop.distanceKm != null) ...[
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.near_me_rounded,
                                        color: Color(0xFF95A5A6),
                                        size: 12,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        '${shop.distanceKm} km',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF7F8C8D),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.phone_in_talk_rounded,
                                      color: Color(0xFF95A5A6),
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        shop.phone,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF7F8C8D),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.place_rounded,
                                      size: 13,
                                      color: Color(0xFFBDC3C7),
                                    ),
                                    const SizedBox(width: 3),
                                    Expanded(
                                      child: Text(
                                        shop.address,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: Color(0xFF95A5A6),
                                          height: 1.3,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 30,
                            height: 30,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFDF6EE),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: Color(0xFFE67E22),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  // ─────────── VOUCHER SLIDER ───────────

  Widget _buildVoucherSlider(
    AppLocalizations l10n,
    List<VoucherModel> visibleVouchers,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE67E22).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.local_offer_rounded,
                  color: Color(0xFFE67E22),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.homePromoForYou,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE67E22),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "${visibleVouchers.length}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 88,
          child: PageView.builder(
            controller: _voucherPageController,
            physics: const BouncingScrollPhysics(),
            itemCount: visibleVouchers.length,
            itemBuilder: (context, idx) =>
                _buildVoucherCard(visibleVouchers[idx], l10n),
          ),
        ),
      ],
    );
  }

  String _formatCountdown(Duration d, AppLocalizations l10n) {
    if (d.isNegative) return l10n.homeExpired;
    if (d.inDays >= 1) return '${d.inDays}n ${d.inHours % 24}g';
    if (d.inHours >= 1) {
      return '${d.inHours.toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
    }
    return '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  Widget _buildVoucherCard(VoucherModel voucher, AppLocalizations l10n) {
    final remaining = voucher.endDate.difference(_now);
    final isSaved = _savedVoucherIds.contains(voucher.id);
    final isFull =
        voucher.claimLimit != null &&
        voucher.claimedCount >= voucher.claimLimit!;
    final isPercent = voucher.discountType == 'percent';
    final isFlash = voucher.claimLimit != null;

    final gradientColors = isFlash
        ? [const Color(0xFFFFF0E0), const Color(0xFFFFD9B3)]
        : [const Color(0xFFE8F4FD), const Color(0xFFD0EAFA)];
    final accentColor = isFlash
        ? const Color(0xFFE67E22)
        : const Color(0xFF2980B9);
    final borderColor = isFlash
        ? const Color(0xFFFFB347)
        : const Color(0xFF87CEEB);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon tròn bên trái
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.confirmation_num_rounded,
              color: accentColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),

          // Thông tin voucher ở giữa
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        voucher.voucherName,
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isFlash) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE74C3C),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          l10n.homeFlash,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  isPercent
                      ? l10n.homeDiscountPercentFormat(
                          voucher.discountValue.toInt().toString(),
                          CurrencyFormatter.formatVND(
                            voucher.maxDiscountAmount ?? 0,
                          ),
                        )
                      : l10n.homeDiscountFormat(
                          CurrencyFormatter.formatVND(voucher.discountValue),
                          CurrencyFormatter.formatVND(voucher.minOrderAmount),
                        ),
                  style: const TextStyle(
                    color: Color(0xFF555555),
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 10,
                      color: remaining.inHours < 3
                          ? const Color(0xFFE74C3C)
                          : const Color(0xFF7F8C8D),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      remaining.isNegative
                          ? l10n.homeExpired
                          : _formatCountdown(remaining, l10n),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: remaining.inHours < 3
                            ? const Color(0xFFE74C3C)
                            : const Color(0xFF7F8C8D),
                      ),
                    ),
                    if (isFlash) ...[
                      const SizedBox(width: 8),
                      Text(
                        isFull
                            ? l10n.homeSoldOutVouchers
                            : l10n.homeRemainingVouchers(
                                (voucher.claimLimit! - voucher.claimedCount)
                                    .toString(),
                              ),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isFull
                              ? const Color(0xFFBDC3C7)
                              : const Color(0xFFE67E22),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Nút lưu bên phải
          GestureDetector(
            onTap: isFull || isSaved || remaining.isNegative
                ? null
                : () {
                    setState(() => _savedVoucherIds.add(voucher.id));
                    // Cập nhật optimistic count trong Cubit và lưu lên backend
                    context.read<HomeCubit>().saveVoucher(voucher.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.homeClaimedVoucherSnackbar(voucher.voucherCode),
                        ),
                        backgroundColor: const Color(0xFF27AE60),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isFull || remaining.isNegative
                    ? const Color(0xFFECF0F1)
                    : isSaved
                    ? const Color(0xFF27AE60)
                    : accentColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                isFull || remaining.isNegative
                    ? l10n.homeSoldOutVouchers
                    : isSaved
                    ? l10n.homeClaimed
                    : l10n.homeClaimVoucher,
                style: TextStyle(
                  color: isFull || remaining.isNegative
                      ? const Color(0xFFBDC3C7)
                      : Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
