import 'package:logger/logger.dart';

import '../core/result.dart';
import '../models/address.model.dart';
import '../services/api_service.dart';
import 'address_repository.dart';
import '../l10n/app_strings.dart';

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
      return Failure(AppStrings.current.errorLoadAddresses);
    }
  }

  @override
  Future<Result<AddressModel>> createAddress({
    required String receiverName,
    required String receiverPhone,
    required String addressDetail,
    bool isDefault = false,
    String label = 'other',
    double? latitude,
    double? longitude,
  }) async {
    try {
      final res = await apiService.post('/api/addresses', {
        'receiver_name': receiverName,
        'receiver_phone': receiverPhone,
        'address_detail': addressDetail,
        'is_default': isDefault,
        'label': label,
        'latitude': ?latitude,
        'longitude': ?longitude,
      });

      if (res['data'] != null) {
        return Success(
          AddressModel.fromJson(res['data'] as Map<String, dynamic>),
        );
      }
      return Failure(res['msg'] ?? AppStrings.current.errorAddAddress);
    } catch (e, s) {
      _log.e('[createAddress] Failed', error: e, stackTrace: s);
      return Failure(AppStrings.current.errorAddAddress);
    }
  }

  @override
  Future<Result<AddressModel>> updateAddress({
    required String id,
    String? receiverName,
    String? receiverPhone,
    String? addressDetail,
    bool? isDefault,
    String? label,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final res = await apiService.put('/api/addresses/$id', {
        'receiver_name': ?receiverName,
        'receiver_phone': ?receiverPhone,
        'address_detail': ?addressDetail,
        'is_default': ?isDefault,
        'label': ?label,
        'latitude': ?latitude,
        'longitude': ?longitude,
      });

      if (res['data'] != null) {
        return Success(
          AddressModel.fromJson(res['data'] as Map<String, dynamic>),
        );
      }
      return Failure(res['msg'] ?? AppStrings.current.errorUpdateAddress);
    } catch (e, s) {
      _log.e('[updateAddress] Failed', error: e, stackTrace: s);
      return Failure(AppStrings.current.errorUpdateAddress);
    }
  }

  @override
  Future<Result<bool>> deleteAddress(String id) async {
    try {
      final res = await apiService.delete('/api/addresses/$id');
      if (res['data'] != null) {
        return const Success(true);
      }
      return Failure(res['msg'] ?? AppStrings.current.errorDeleteAddress);
    } catch (e, s) {
      _log.e('[deleteAddress] Failed', error: e, stackTrace: s);
      return Failure(AppStrings.current.errorDeleteAddress);
    }
  }
}
