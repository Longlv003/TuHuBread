import 'package:logger/logger.dart';

import '../core/result.dart';
import '../models/voucher.model.dart';
import '../models/voucher_save.model.dart';
import '../services/api_service.dart';
import 'voucher_repository.dart';

final _log = Logger(
  printer: PrettyPrinter(methodCount: 1, colors: true, printEmojis: true),
);

class VoucherRepositoryImpl implements VoucherRepository {
  final ApiService apiService;

  const VoucherRepositoryImpl({required this.apiService});

  @override
  Future<Result<List<VoucherSaveModel>>> fetchSavedVouchers() async {
    try {
      final res = await apiService.get('/api/vouchers/saved');
      final data = res['data'];
      if (data == null) return const Success([]);

      final saves = (data as List)
          .map((e) => VoucherSaveModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return Success(saves);
    } catch (e, s) {
      _log.e('[fetchSavedVouchers] Failed', error: e, stackTrace: s);
      return const Failure('Không thể tải danh sách voucher đã lưu');
    }
  }

  @override
  Future<Result<List<VoucherModel>>> fetchAvailableVouchers() async {
    try {
      final res = await apiService.get('/api/vouchers');
      final data = res['data'];
      if (data == null) return const Success([]);

      final vouchers = (data as List)
          .map((e) => VoucherModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return Success(vouchers);
    } catch (e, s) {
      _log.e('[fetchAvailableVouchers] Failed', error: e, stackTrace: s);
      return const Failure('Không thể tải danh sách voucher');
    }
  }

  @override
  Future<Result<VoucherSaveModel>> redeemByCode(String code) async {
    try {
      final res = await apiService.post('/api/vouchers/redeem', {'voucher_code': code});
      if (res['data'] != null) {
        return Success(VoucherSaveModel.fromJson(res['data'] as Map<String, dynamic>));
      }
      return Failure(res['msg'] ?? 'Không thể áp dụng mã voucher');
    } catch (e, s) {
      _log.e('[redeemByCode] Failed', error: e, stackTrace: s);
      return const Failure('Không thể áp dụng mã voucher');
    }
  }

  @override
  Future<Result<bool>> saveVoucher(String voucherId) async {
    try {
      final res = await apiService.post('/api/vouchers/$voucherId/save', {});
      if (res['data'] != null) {
        return const Success(true);
      }
      return Failure(res['msg'] ?? 'Không thể lưu voucher');
    } catch (e, s) {
      _log.e('[saveVoucher] Failed', error: e, stackTrace: s);
      return const Failure('Không thể lưu voucher');
    }
  }
}
