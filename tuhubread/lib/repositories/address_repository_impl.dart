import 'package:logger/logger.dart';

import '../core/result.dart';
import '../models/address.model.dart';
import '../services/api_service.dart';
import 'address_repository.dart';

final _log = Logger(
  printer: PrettyPrinter(methodCount: 1, colors: true, printEmojis: true),
);

class AddressRepositoryImpl implements AddressRepository {
  final ApiService apiService;

  const AddressRepositoryImpl({required this.apiService});

  @override
  Future<Result<List<AddressModel>>> fetchMyAddresses() async {
    try {
      final res = await apiService.get('/api/addresses');
      final data = res['data'];
      if (data == null) return const Success([]);

      final addresses = (data as List)
          .map((e) => AddressModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return Success(addresses);
    } catch (e, s) {
      _log.e('[fetchMyAddresses] Failed', error: e, stackTrace: s);
      return const Failure('Không thể tải danh sách địa chỉ');
    }
  }

  @override
  Future<Result<AddressModel>> createAddress({
    required String receiverName,
    required String receiverPhone,
    required String addressDetail,
    bool isDefault = false,
  }) async {
    try {
      final res = await apiService.post('/api/addresses', {
        'receiver_name': receiverName,
        'receiver_phone': receiverPhone,
        'address_detail': addressDetail,
        'is_default': isDefault,
      });

      if (res['data'] != null) {
        return Success(AddressModel.fromJson(res['data'] as Map<String, dynamic>));
      }
      return Failure(res['msg'] ?? 'Không thể thêm địa chỉ');
    } catch (e, s) {
      _log.e('[createAddress] Failed', error: e, stackTrace: s);
      return const Failure('Không thể thêm địa chỉ');
    }
  }

  @override
  Future<Result<AddressModel>> updateAddress({
    required String id,
    String? receiverName,
    String? receiverPhone,
    String? addressDetail,
    bool? isDefault,
  }) async {
    try {
      final res = await apiService.put('/api/addresses/$id', {
        if (receiverName != null) 'receiver_name': receiverName,
        if (receiverPhone != null) 'receiver_phone': receiverPhone,
        if (addressDetail != null) 'address_detail': addressDetail,
        if (isDefault != null) 'is_default': isDefault,
      });

      if (res['data'] != null) {
        return Success(AddressModel.fromJson(res['data'] as Map<String, dynamic>));
      }
      return Failure(res['msg'] ?? 'Không thể cập nhật địa chỉ');
    } catch (e, s) {
      _log.e('[updateAddress] Failed', error: e, stackTrace: s);
      return const Failure('Không thể cập nhật địa chỉ');
    }
  }

  @override
  Future<Result<bool>> deleteAddress(String id) async {
    try {
      final res = await apiService.delete('/api/addresses/$id');
      if (res['data'] != null) {
        return const Success(true);
      }
      return Failure(res['msg'] ?? 'Không thể xóa địa chỉ');
    } catch (e, s) {
      _log.e('[deleteAddress] Failed', error: e, stackTrace: s);
      return const Failure('Không thể xóa địa chỉ');
    }
  }
}
