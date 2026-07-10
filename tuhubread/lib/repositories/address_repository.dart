import '../core/result.dart';
import '../models/address.model.dart';

abstract class AddressRepository {
  Future<Result<List<AddressModel>>> fetchMyAddresses();

  Future<Result<AddressModel>> createAddress({
    required String receiverName,
    required String receiverPhone,
    required String addressDetail,
    bool isDefault,
  });

  Future<Result<AddressModel>> updateAddress({
    required String id,
    String? receiverName,
    String? receiverPhone,
    String? addressDetail,
    bool? isDefault,
  });

  Future<Result<bool>> deleteAddress(String id);
}
