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

  /// Số thứ tự lần tải trang chủ gần nhất — dùng để loại bỏ kết quả của các
  /// lần tải cũ về muộn hơn (xem [loadHomeData]).
  int _loadRequestId = 0;

  /// Đổi địa chỉ giao hàng -> tính lại danh sách cửa hàng gần. Bỏ qua nếu toạ
  /// độ không đổi để tránh gọi lại API thừa mỗi lần rebuild.
  ///
  /// Toạ độ được lưu trong [LocationService] (singleton) chứ không phải trong
  /// cubit này, vì HomeCubit đăng ký dạng factory nên sẽ bị tạo mới mỗi lần
  /// màn hình chính dựng lại.
  Future<void> updateDeliveryLocation(double? lat, double? lng) async {
    final current = locationService.deliveryCoordinates;
    if (lat == current?.latitude && lng == current?.longitude) return;
    locationService.setDeliveryCoordinates(lat, lng);
    await loadHomeData();
  }

  // ─────────── LOAD ALL HOME DATA ───────────

  /// Gọi tất cả API song song — 1 API fail KHÔNG crash toàn bộ.
  /// Mỗi repo method đã wrap try/catch riêng → Future.wait không throw.
  /// Sections lỗi sẽ hiện rỗng, lỗi được ghi vào [HomeLoaded.sectionErrors].
  Future<void> loadHomeData() async {
    // Đánh dấu lần tải này. Trang chủ có thể bị gọi tải nhiều lần chồng nhau
    // (lần đầu lúc mở app, lần sau khi biết địa chỉ giao hàng), mà lần chạy
    // trước thường CHẬM hơn vì phải chờ GPS tới 6 giây. Nếu không chặn, kết
    // quả cũ (chưa có toạ độ -> backend trả TẤT CẢ cửa hàng) sẽ về sau và ghi
    // đè lên kết quả mới đã lọc đúng, làm danh sách nhảy loạn.
    final requestId = ++_loadRequestId;

    // Chỉ hiện khung chờ khi chưa có gì để xem. Các lần tải lại sau đó (vd.
    // khi đã biết địa chỉ giao hàng) giữ nguyên nội dung cũ trên màn hình,
    // tránh chớp skeleton giữa chừng.
    if (state is! HomeLoaded) emit(const HomeLoading());

    // Ưu tiên toạ độ địa chỉ giao hàng đang chọn, không có thì lùi về GPS.
    // Timeout ở đây là lớp bảo vệ để trang chủ không bị treo khi máy bắt GPS
    // chậm — khi hết giờ vẫn dùng vị trí lấy được gần nhất thay vì bỏ trống,
    // vì bỏ trống sẽ khiến backend trả về TẤT CẢ cửa hàng (kể cả rất xa).
    final coords = await locationService.resolveNearbyCoordinates().timeout(
          const Duration(seconds: 8),
          onTimeout: () => locationService.lastKnownCoordinates,
        );

    // Đã có lần tải mới hơn trong lúc chờ GPS -> bỏ luôn, không gọi API thừa.
    if (requestId != _loadRequestId || isClosed) return;

    final lat = coords?.latitude;
    final lng = coords?.longitude;

    // Gọi song song — mỗi Future là Result<T>, không bao giờ throw
    final (
      shopsRes,
      categoriesRes,
      productsRes,
      bestSellersRes,
      vouchersRes,
    ) = await (
      repository.fetchShops(lat: lat, lng: lng),
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

    // Kết quả này đã cũ so với lần tải mới nhất -> bỏ, giữ nguyên dữ liệu
    // đang hiển thị.
    if (requestId != _loadRequestId || isClosed) return;

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
