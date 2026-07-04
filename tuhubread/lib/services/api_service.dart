import 'package:dio/dio.dart';
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

      return {
        "msg": response.data['msg'] ?? "Success",
        "data": response.data['data'],
      };
    } on DioException catch (e) {
      return {
        "msg": e.response?.data['msg'] ?? e.message ?? "Request failed",
        "data": null,
      };
    }
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
