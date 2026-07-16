import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tuhubread/configs/system.dart';

class ApiService {
  late final Dio _dio;

  ApiService({String? token}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: URL.getBaseURL(),
        connectTimeout: const Duration(milliseconds: System.connectionTimeout),
        receiveTimeout: const Duration(milliseconds: System.receiveTimeout),
        headers: System.header(),
      ),
    );

    // Luôn lấy ID token mới nhất từ Firebase trước mỗi request — tránh lỗi
    // 401 "Invalid token" khi token cũ (set 1 lần lúc đăng nhập) đã hết hạn
    // sau 1 giờ. Firebase SDK tự cache & chỉ refresh khi cần, nên không tốn
    // thêm round-trip network trong phần lớn trường hợp.
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            try {
              final freshToken = await user.getIdToken();
              options.headers['Authorization'] = 'Bearer $freshToken';
            } catch (_) {
              // Giữ header cũ (nếu có) nếu không lấy được token mới
            }
          }
          handler.next(options);
        },
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(request: true, requestBody: true, responseBody: true),
    );
  }

  Future<Map<String, dynamic>> request(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? queryParameters,
    dynamic data,
  }) async {
    try {
      final response = await _dio.request(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(method: method),
      );

      final responseData = response.data;
      if (responseData is Map<String, dynamic>) {
        return {
          "msg": responseData['msg'] ?? "Success",
          "data": responseData['data'],
        };
      }
      return {
        "msg": "Success",
        "data": responseData,
      };
    } on DioException catch (e) {
      final errData = e.response?.data;
      String errorMsg = e.message ?? "Request failed";

      if (errData is Map<String, dynamic>) {
        errorMsg = errData['msg']?.toString() ?? errorMsg;
      } else if (errData is String && errData.isNotEmpty) {
        errorMsg = _sanitizeErrorMessage(errData, e.response?.statusCode);
      } else if (e.response?.statusCode == 404) {
        errorMsg = 'Không tìm thấy dữ liệu yêu cầu';
      }

      return {
        "msg": errorMsg,
        "data": null,
      };
    }
  }

  /// Chuyển HTML/plain-text lỗi từ server thành thông báo thân thiện.
  String _sanitizeErrorMessage(String raw, int? statusCode) {
    final lower = raw.toLowerCase();
    if (lower.contains('<!doctype html') || lower.contains('<html')) {
      if (lower.contains('cannot get')) {
        return 'API chưa được cấu hình hoặc không tồn tại';
      }
      if (statusCode == 404) {
        return 'Không tìm thấy dữ liệu yêu cầu';
      }
      return 'Lỗi kết nối máy chủ';
    }
    return raw;
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) {
    return request(path, method: 'GET', queryParameters: query);
  }

  Future<Map<String, dynamic>> post(String path, dynamic body) {
    return request(path, method: 'POST', data: body);
  }

  Future<Map<String, dynamic>> put(String path, dynamic body) {
    return request(path, method: 'PUT', data: body);
  }

  Future<Map<String, dynamic>> delete(String path) {
    return request(path, method: 'DELETE');
  }

  void updateToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }
}
