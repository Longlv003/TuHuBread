import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../core/result.dart';
import '../../models/voucher.model.dart';
import '../../models/shop_category.model.dart';
import '../../repositories/home_repository.dart';
import 'home_state.dart';

final _log = Logger(
  printer: PrettyPrinter(methodCount: 1, colors: true, printEmojis: true),
);

class HomeCubit extends Cubit<HomeState> {
  final HomeRepository repository;

  HomeCubit({required this.repository}) : super(const HomeInitial());

  /// Load danh mục của shop cụ thể
  Future<void> loadShopCategories(String shopId) async {
    if (state is! HomeLoaded) return;
    final current = state as HomeLoaded;

    if (shopId.isEmpty) {
      emit(current.copyWith(shopCategories: []));
      return;
    }

    final res = await repository.fetchShopCategories(shopId);
    if (res is Success<List<ShopCategoryModel>>) {
      emit(current.copyWith(shopCategories: res.dataOrNull ?? []));
    } else {
      _log.e('[loadShopCategories] Failed: ${res.errorOrNull}');
      emit(current.copyWith(shopCategories: []));
    }
  }

  // ─────────── LOAD ALL HOME DATA ───────────

  /// Gọi tất cả API song song — 1 API fail KHÔNG crash toàn bộ.
  /// Mỗi repo method đã wrap try/catch riêng → Future.wait không throw.
  /// Sections lỗi sẽ hiện rỗng, lỗi được ghi vào [HomeLoaded.sectionErrors].
  Future<void> loadHomeData() async {
    emit(const HomeLoading());

    // Gọi song song — mỗi Future là Result<T>, không bao giờ throw
    final (
      shopsRes,
      categoriesRes,
      productsRes,
      bestSellersRes,
      saleRes,
      vouchersRes,
    ) = await (
      repository.fetchShops(),
      repository.fetchCategories(),
      repository.fetchProducts(),
      repository.fetchBestSellers(),
      repository.fetchSaleProducts(),
      repository.fetchActiveVouchers(),
    ).wait;

    // Thu thập lỗi từng section (không throw, chỉ log + hiện UI warning)
    final errors = <String, String>{};
    _collectError(errors, 'shops', shopsRes);
    _collectError(errors, 'categories', categoriesRes);
    _collectError(errors, 'products', productsRes);
    _collectError(errors, 'bestSellers', bestSellersRes);
    _collectError(errors, 'saleProducts', saleRes);
    _collectError(errors, 'vouchers', vouchersRes);

    if (errors.isNotEmpty) {
      _log.w(
        '[HomeCubit] Partial load — failed sections: ${errors.keys.join(', ')}',
      );
    } else {
      _log.i('[HomeCubit] All sections loaded OK');
    }

    final saleData = saleRes.dataOrNull;

    // Luôn emit HomeLoaded — UI không bao giờ crash
    emit(
      HomeLoaded(
        shops: shopsRes.getOrElse([]),
        categories: categoriesRes.getOrElse([]),
        products: productsRes.getOrElse([]),
        bestSellers: bestSellersRes.getOrElse([]),
        saleProducts: saleData?.products ?? [],
        productSales: saleData?.sales ?? [],
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
