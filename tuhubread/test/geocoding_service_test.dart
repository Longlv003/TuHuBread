import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuhubread/services/geocoding_service.dart';

/// Giả lập tầng mạng: cho phép ép Nominatim lỗi để kiểm tra có tự chuyển
/// sang Photon không.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter({required this.nominatimFails});
  final bool nominatimFails;
  final List<String> calledHosts = [];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? _, Future? __) async {
    calledHosts.add(options.uri.host);
    if (options.uri.host.contains('nominatim')) {
      if (nominatimFails) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: 'Connection reset by peer',
        );
      }
      return ResponseBody.fromString(
        '[{"display_name":"Tran Phu, Ha Noi","lat":"21.03","lon":"105.80"}]',
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }
    // Photon
    return ResponseBody.fromString(
      '{"features":[{"properties":{"street":"Duong Tran Phu","city":"Ha Noi","country":"Viet Nam"},'
      '"geometry":{"coordinates":[105.79,20.98]}}]}',
      200,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('Nominatim chạy được thì dùng luôn, không gọi Photon', () async {
    final adapter = _FakeAdapter(nominatimFails: false);
    final dio = Dio()..httpClientAdapter = adapter;
    final results = await GeocodingService(dio: dio).search('tran phu');

    expect(results.single.displayName, 'Tran Phu, Ha Noi');
    expect(adapter.calledHosts.any((h) => h.contains('photon')), isFalse);
  });

  test('Nominatim lỗi kết nối thì tự chuyển sang Photon', () async {
    final adapter = _FakeAdapter(nominatimFails: true);
    final dio = Dio()..httpClientAdapter = adapter;
    final results = await GeocodingService(dio: dio).search('tran phu');

    expect(results, isNotEmpty);
    expect(results.single.displayName, contains('Duong Tran Phu'));
    expect(results.single.latitude, 20.98);
    expect(results.single.longitude, 105.79);
    expect(adapter.calledHosts.any((h) => h.contains('photon')), isTrue);
  });

  test('Dịch ngược toạ độ cũng có dự phòng', () async {
    final adapter = _FakeAdapter(nominatimFails: true);
    final dio = Dio()..httpClientAdapter = adapter;
    final place = await GeocodingService(dio: dio).reverse(20.98, 105.79);

    expect(place, isNotNull);
    expect(place!.displayName, contains('Ha Noi'));
    expect(place.street, 'Duong Tran Phu');
  });
}
