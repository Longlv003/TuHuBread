import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../core/result.dart';
import '../../models/voucher.model.dart';
import '../../repositories/home_repository.dart';
import '../../services/location_service.dart';
import 'home_state.dart';

final _log = Logger(
  printer: PrettyPrinter(methodCount: 1, colors: true, printEmojis: true),
);

class HomeCubit extends Cubit<HomeState> {
  final HomeRepository repository;
  final LocationService locationService;

  HomeCubit({required this.repository, required this.locationService})
      : super(const HomeInitial());

  // ─────────── LOAD ALL HOME DATA ───────────

  /// Gọi tất cả API song song — 1 API fail KHÔNG crash toàn bộ.
  /// Mỗi repo method đã wrap try/catch riêng → Future.wait không throw.
  /// Sections lỗi sẽ hiện rỗng, lỗi được ghi vào [HomeLoaded.sectionErrors].
  Future<void> loadHomeData() async {
    emit(const HomeLoading());

    // Best-effort lấy GPS trước để tìm shop gần — không chặn màn hình nếu bị
    // từ chối quyền hoặc tắt định vị (trả về null, backend fallback về danh
    // sách shop không sắp xếp theo khoảng cách). Có thêm timeout ở đây làm
    // lớp bảo vệ thứ 2 (ngoài timeout trong LocationService) — nếu vì lý do
    // gì đó việc xin quyền/định vị bị treo, trang chủ vẫn phải tải được.
    final coords = await locationService
        .getCurrentCoordinates()
        .timeout(const Duration(seconds: 8), onTimeout: () => null);

    // Gọi song song — mỗi Future là Result<T>, không bao giờ throw
    final (
      shopsRes,
      categoriesRes,
      productsRes,
      bestSellersRes,
      vouchersRes,
    ) = await (
      repository.fetchShops(lat: coords?.latitude, lng: coords?.longitude),
      repository.fetchCategories(),
      repository.fetchProducts(),
      repository.fetchBestSellers(),
      repository.fetchActiveVouchers(),
    ).wait;

    // Thu thập lỗi từng section (không throw, chỉ log + hiện UI warning)
    final errors = <String, String>{};
    _collectError(errors, 'shops', shopsRes);
    _collectError(errors, 'categories', categoriesRes);
    _collectError(errors, 'products', productsRes);
    _collectError(errors, 'bestSellers', bestSellersRes);
    _collectError(errors, 'vouchers', vouchersRes);

    if (errors.isNotEmpty) {
      _log.w(
        '[HomeCubit] Partial load — failed sections: ${errors.keys.join(', ')}',
      );
    } else {
      _log.i('[HomeCubit] All sections loaded OK');
    }

    // Luôn emit HomeLoaded — UI không bao giờ crash
    emit(
      HomeLoaded(
        shops: shopsRes.getOrElse([]),
        categories: categoriesRes.getOrElse([]),
        products: productsRes.getOrElse([]),
        bestSellers: bestSellersRes.getOrElse([]),
        vouchers: vouchersRes.getOrElse([]),
        sectionErrors: errors,
      ),
    );
  }

  // ─────────── REFRESH ───────────

  /// Refresh — giữ data cũ trong khi tải lại (tránh flash màn hình trắng)
  Future<void> refresh() async {
    if (state is! HomeLoaded) emit(const HomeLoading());
    await loadHomeData();
  }

  // ─────────── SAVE VOUCHER (LOCAL OPTIMISTIC UPDATE) ───────────

  /// Optimistic update: tăng claimedCount ngay trên UI mà không cần chờ API,
  /// đồng thời gửi yêu cầu lưu voucher thật lên backend.
  Future<void> saveVoucher(String voucherId) async {
    if (state is! HomeLoaded) return;
    final current = state as HomeLoaded;

    // 1. Optimistic Update
    final updatedVouchers = current.vouchers.map((v) {
      if (v.id != voucherId) return v;
      return VoucherModel(
        id: v.id,
        shopId: v.shopId,
        voucherCode: v.voucherCode,
        voucherName: v.voucherName,
        voucherType: v.voucherType,
        discountType: v.discountType,
        discountValue: v.discountValue,
        minOrderAmount: v.minOrderAmount,
        maxDiscountAmount: v.maxDiscountAmount,
        claimLimit: v.claimLimit,
        claimedCount: v.claimedCount + 1,
        usageLimit: v.usageLimit,
        usedCount: v.usedCount,
        startDate: v.startDate,
        endDate: v.endDate,
        status: v.status,
      );
    }).toList();

    emit(current.copyWith(vouchers: updatedVouchers));

    // 2. Call API
    final res = await repository.saveVoucher(voucherId);
    if (res is Failure) {
      _log.e('[saveVoucher] Failed to save on server: ${res.errorOrNull}');
    } else {
      _log.i('[saveVoucher] Saved voucher $voucherId successfully on server');
    }
  }

  // ─────────── PRIVATE HELPERS ───────────

  void _collectError<T>(
    Map<String, String> errors,
    String key,
    Result<T> result,
  ) {
    final err = result.errorOrNull;
    if (err != null) errors[key] = err;
  }
}
