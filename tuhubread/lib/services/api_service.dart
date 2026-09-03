import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tuhubread/configs/system.dart';
import '../l10n/app_strings.dart';

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

    // Chỉ log request/response ở debug build — LogInterceptor mặc định in cả
    // request header (bao gồm Bearer token) nên tuyệt đối không được bật ở release.
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: false,
          requestBody: true,
          responseBody: true,
        ),
      );
    }
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
        // Không cần tự xoá/ghi đè header Content-Type cho FormData: Dio luôn
        // tự ghi đè header này thành `multipart/form-data; boundary=...`
        // ngay trước khi gửi (dio_mixin._transformData), bất kể BaseOptions
        // đặt sẵn Content-Type: application/json hay không.
        // Truyền `headers: {'Content-Type': null}` để "xoá" header tưởng như
        // đúng nhưng lại gây crash: Options.compose() merge header đó vào bản
        // sao rồi so sánh với contentType lấy từ BaseOptions gốc (vẫn còn
        // 'application/json') — 2 giá trị lệch nhau (null vs 'application/json')
        // khiến RequestOptions ném ArgumentError "Unable to set different
        // values for `contentType` and the content-type header." trước khi
        // request kịp gửi đi.
        options: Options(method: method),
      );

      final responseData = response.data;
      // "success" phản ánh đúng việc request có 2xx hay không — không nên suy
      // luận thành công/thất bại từ "msg"/"data" vì nhiều endpoint (vd. huỷ đăng
      // ký device token) luôn trả data: null kể cả khi thành công.
      if (responseData is Map<String, dynamic>) {
        return {
          "msg": responseData['msg'] ?? "Success",
          "data": responseData['data'],
          "success": true,
          "statusCode": response.statusCode,
        };
      }
      return {
        "msg": "Success",
        "data": responseData,
        "success": true,
        "statusCode": response.statusCode,
      };
    } on DioException catch (e) {
      final errData = e.response?.data;
      String errorMsg = e.message ?? "Request failed";

      if (errData is Map<String, dynamic>) {
        errorMsg = errData['msg']?.toString() ?? errorMsg;
      } else if (errData is String && errData.isNotEmpty) {
        errorMsg = _sanitizeErrorMessage(errData, e.response?.statusCode);
      } else if (e.response?.statusCode == 404) {
        errorMsg = AppStrings.current.errorDataNotFound;
      }

      return {
        "msg": errorMsg,
        "data": null,
        "success": false,
        // null khi request còn chưa tới được server (mất mạng, sai IP, timeout)
        // — khác hẳn với việc server trả về lỗi có mã cụ thể.
        "statusCode": e.response?.statusCode,
      };
    }
  }

  /// Chuyển HTML/plain-text lỗi từ server thành thông báo thân thiện.
  String _sanitizeErrorMessage(String raw, int? statusCode) {
    final lower = raw.toLowerCase();
    if (lower.contains('<!doctype html') || lower.contains('<html')) {
      if (lower.contains('cannot get')) {
        return AppStrings.current.errorApiNotConfigured;
      }
      if (statusCode == 404) {
        return AppStrings.current.errorDataNotFound;
      }
      return AppStrings.current.errorServerConnection;
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
