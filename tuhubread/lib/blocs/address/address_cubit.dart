import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../core/result.dart';
import '../../models/address.model.dart';
import '../../repositories/address_repository.dart';
import 'address_state.dart';

final _log = Logger(
  printer: PrettyPrinter(methodCount: 1, colors: true, printEmojis: true),
);

class AddressCubit extends Cubit<AddressState> {
  final AddressRepository repository;

  AddressCubit({required this.repository}) : super(const AddressInitial());

  Future<void> loadMyAddresses() async {
    emit(const AddressLoading());
    final res = await repository.fetchMyAddresses();
    if (res is Success<List<AddressModel>>) {
      emit(AddressLoaded(res.data));
    } else {
      _log.e('[loadMyAddresses] Failed: ${res.errorOrNull}');
      emit(AddressFailure(res.errorOrNull ?? 'Không thể tải địa chỉ'));
    }
  }

  Future<bool> addAddress({
    required String receiverName,
    required String receiverPhone,
    required String addressDetail,
    bool isDefault = false,
    String label = 'other',
    double? latitude,
    double? longitude,
  }) async {
    final res = await repository.createAddress(
      receiverName: receiverName,
      receiverPhone: receiverPhone,
      addressDetail: addressDetail,
      isDefault: isDefault,
      label: label,
      latitude: latitude,
      longitude: longitude,
    );

    if (res is Success<AddressModel>) {
      await loadMyAddresses();
      return true;
    }
    _log.e('[addAddress] Failed: ${res.errorOrNull}');
    return false;
  }

  Future<bool> editAddress({
    required String id,
    String? receiverName,
    String? receiverPhone,
    String? addressDetail,
    bool? isDefault,
    String? label,
    double? latitude,
    double? longitude,
  }) async {
    final res = await repository.updateAddress(
      id: id,
      receiverName: receiverName,
      receiverPhone: receiverPhone,
      addressDetail: addressDetail,
      isDefault: isDefault,
      label: label,
      latitude: latitude,
      longitude: longitude,
    );

    if (res is Success<AddressModel>) {
      await loadMyAddresses();
      return true;
    }
    _log.e('[editAddress] Failed: ${res.errorOrNull}');
    return false;
  }

  Future<bool> setDefault(String id) => editAddress(id: id, isDefault: true);

  Future<bool> removeAddress(String id) async {
    if (state is! AddressLoaded) return false;
    final current = state as AddressLoaded;

    // Optimistic update: xoá khỏi UI ngay, khôi phục nếu API lỗi
    final previous = current.addresses;
    emit(
      current.copyWith(addresses: previous.where((a) => a.id != id).toList()),
    );

    final res = await repository.deleteAddress(id);
    if (res is Failure<bool>) {
      _log.e('[removeAddress] Failed: ${res.message}');
      emit(current.copyWith(addresses: previous, actionError: res.message));
      return false;
    }
    return true;
  }
}
