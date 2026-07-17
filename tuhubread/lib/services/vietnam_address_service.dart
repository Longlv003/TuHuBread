import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../models/province.model.dart';
import '../models/ward.model.dart';

final _log = Logger(
  printer: PrettyPrinter(methodCount: 1, colors: true, printEmojis: true),
);

/// Gọi API công khai provinces.open-api.vn (v2 — dữ liệu sau sáp nhập
/// hành chính 07/2025, chỉ còn 2 cấp: Tỉnh/Thành phố -> Phường/Xã).
class VietnamAddressService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://provinces.open-api.vn/api/v2/',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  Future<List<ProvinceModel>> fetchProvinces() async {
    try {
      final res = await _dio.get('p/');
      final list = res.data as List;
      return list
          .map((e) => ProvinceModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, s) {
      _log.e('[fetchProvinces] Failed', error: e, stackTrace: s);
      return [];
    }
  }

  Future<List<WardModel>> fetchWardsByProvince(int provinceCode) async {
    try {
      final res = await _dio.get('p/$provinceCode', queryParameters: {'depth': 2});
      final wards = res.data['wards'] as List? ?? [];
      return wards
          .map((e) => WardModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, s) {
      _log.e('[fetchWardsByProvince] Failed', error: e, stackTrace: s);
      return [];
    }
  }
}
