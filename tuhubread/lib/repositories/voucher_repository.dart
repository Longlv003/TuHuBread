import '../core/result.dart';
import '../models/voucher.model.dart';
import '../models/voucher_save.model.dart';

abstract class VoucherRepository {
  Future<Result<List<VoucherSaveModel>>> fetchSavedVouchers();

  /// Voucher đang hoạt động mà user chưa lưu vào ví
  Future<Result<List<VoucherModel>>> fetchAvailableVouchers();

  Future<Result<VoucherSaveModel>> redeemByCode(String code);

  Future<Result<bool>> saveVoucher(String voucherId);
}
