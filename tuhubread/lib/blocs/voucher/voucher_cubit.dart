import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../core/result.dart';
import '../../models/voucher_save.model.dart';
import '../../repositories/voucher_repository.dart';
import 'voucher_state.dart';
import 'package:tuhubread/l10n/app_strings.dart';

final _log = Logger(
  printer: PrettyPrinter(methodCount: 1, colors: true, printEmojis: true),
);

class VoucherCubit extends Cubit<VoucherState> {
  final VoucherRepository repository;

  VoucherCubit({required this.repository}) : super(const VoucherInitial());

  /// Tải song song ví voucher đã lưu + voucher đang có thể lưu.
  Future<void> loadVouchers() async {
    emit(const VoucherLoading());

    final (savedRes, availableRes) = await (
      repository.fetchSavedVouchers(),
      repository.fetchAvailableVouchers(),
    ).wait;

    if (savedRes is Success<List<VoucherSaveModel>>) {
      emit(VoucherLoaded(
        savedRes.data,
        availableVouchers: availableRes.getOrElse([]),
      ));
    } else {
      _log.e('[loadVouchers] Failed: ${savedRes.errorOrNull}');
      emit(VoucherFailure(savedRes.errorOrNull ?? AppStrings.current.errorLoadVouchers));
    }
  }

  /// Trả về null nếu áp dụng mã thành công (và tự tải lại), ngược lại trả về
  /// thông báo lỗi để hiển thị cho người dùng.
  Future<String?> redeemByCode(String code) async {
    final res = await repository.redeemByCode(code);
    if (res is Success<VoucherSaveModel>) {
      await loadVouchers();
      return null;
    }
    return res.errorOrNull ?? AppStrings.current.errorApplyVoucher;
  }

  /// Lưu 1 voucher đang hiển thị ở danh sách "có thể lưu" vào ví.
  Future<String?> saveVoucher(String voucherId) async {
    final res = await repository.saveVoucher(voucherId);
    if (res is Success<bool>) {
      await loadVouchers();
      return null;
    }
    return res.errorOrNull ?? AppStrings.current.errorSaveVoucher;
  }
}
