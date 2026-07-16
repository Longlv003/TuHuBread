import '../../models/voucher.model.dart';
import '../../models/voucher_save.model.dart';

abstract class VoucherState {
  const VoucherState();
}

class VoucherInitial extends VoucherState {
  const VoucherInitial();
}

class VoucherLoading extends VoucherState {
  const VoucherLoading();
}

class VoucherLoaded extends VoucherState {
  final List<VoucherSaveModel> savedVouchers;
  final List<VoucherModel> availableVouchers;

  const VoucherLoaded(this.savedVouchers, {this.availableVouchers = const []});

  VoucherLoaded copyWith({
    List<VoucherSaveModel>? savedVouchers,
    List<VoucherModel>? availableVouchers,
  }) {
    return VoucherLoaded(
      savedVouchers ?? this.savedVouchers,
      availableVouchers: availableVouchers ?? this.availableVouchers,
    );
  }
}

class VoucherFailure extends VoucherState {
  final String error;
  const VoucherFailure(this.error);
}
