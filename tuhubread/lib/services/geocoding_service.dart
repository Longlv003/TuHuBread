import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Một gợi ý địa điểm trả về từ dịch vụ tìm kiếm địa chỉ.
class PlaceResult {
  final String displayName;
  final double latitude;
  final double longitude;

  /// Các mảnh địa chỉ tách sẵn — dùng để điền nhanh form thêm địa chỉ.
  final String? street;
  final String? ward;
  final String? province;

  const PlaceResult({
    required this.displayName,
    required this.latitude,
    required this.longitude,
    this.street,
    this.ward,
    this.province,
  });
}

/// Tìm kiếm và dịch ngược toạ độ ra địa chỉ.
///
/// Dùng 2 nhà cung cấp miễn phí (không cần API key) theo thứ tự ưu tiên:
///   1. Nominatim (OpenStreetMap) — địa chỉ tiếng Việt đầy đủ và sát nhất.
///   2. Photon (Komoot) — dự phòng khi Nominatim không kết nối được.
///
/// Lý do cần dự phòng: đường IPv4 tới nominatim.openstreetmap.org ở một số
/// mạng tại Việt Nam bị chặn/đứt (báo lỗi "Connection reset by peer"), trong
/// khi Photon vẫn vào bình thường. Nếu chỉ dùng một nhà cung cấp thì tính năng
/// chọn địa chỉ trên bản đồ sẽ chết hẳn trên những mạng đó.
class GeocodingService {
  GeocodingService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              // Không có timeout thì khi mạng chập chờn, request treo rất lâu
              // và người dùng tưởng app bị đơ.
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
              // Nominatim BẮT BUỘC có User-Agent định danh ứng dụng, thiếu là
              // bị chặn: https://operations.osmfoundation.org/policies/nominatim/
              headers: {'User-Agent': 'TuHuBreadApp/1.0'},
            ));

  final Dio _dio;

  static const _nominatimBase = 'https://nominatim.openstreetmap.org';
  static const _photonBase = 'https://photon.komoot.io';

  // ─────────── TÌM KIẾM ───────────

  Future<List<PlaceResult>> search(String query) async {
    try {
      return await _searchNominatim(query);
    } catch (e) {
      debugPrint('[GeocodingService] Nominatim search lỗi, chuyển sang Photon: $e');
      return _searchPhoton(query);
    }
  }

  Future<List<PlaceResult>> _searchNominatim(String query) async {
    final res = await _dio.get(
      '$_nominatimBase/search',
      queryParameters: {
        'format': 'json',
        'q': query,
        'countrycodes': 'vn',
        'accept-language': 'vi',
        'limit': 8,
      },
    );
    final list = (res.data as List? ?? []);
    return list
        .map((e) => PlaceResult(
              displayName: e['display_name'] as String,
              latitude: double.parse(e['lat'] as String),
              longitude: double.parse(e['lon'] as String),
            ))
        .toList();
  }

  Future<List<PlaceResult>> _searchPhoton(String query) async {
    final res = await _dio.get(
      '$_photonBase/api/',
      queryParameters: {'q': query, 'limit': 8, 'lang': 'default'},
    );
    final features = ((res.data as Map?)?['features'] as List? ?? []);
    return features
        .map((f) {
          final props = (f['properties'] as Map?) ?? {};
          final coords = (f['geometry'] as Map?)?['coordinates'] as List?;
          if (coords == null || coords.length < 2) return null;
          return PlaceResult(
            displayName: _photonDisplayName(props),
            // GeoJSON là [kinh độ, vĩ độ] — ngược với thứ tự quen dùng.
            longitude: (coords[0] as num).toDouble(),
            latitude: (coords[1] as num).toDouble(),
            street: _photonStreet(props),
            ward: props['district'] as String?,
            province: (props['city'] ?? props['state']) as String?,
          );
        })
        .whereType<PlaceResult>()
        .toList();
  }

  // ─────────── DỊCH NGƯỢC TOẠ ĐỘ ───────────

  Future<PlaceResult?> reverse(double latitude, double longitude) async {
    try {
      return await _reverseNominatim(latitude, longitude);
    } catch (e) {
      debugPrint('[GeocodingService] Nominatim reverse lỗi, chuyển sang Photon: $e');
      try {
        return await _reversePhoton(latitude, longitude);
      } catch (e2) {
        debugPrint('[GeocodingService] Photon reverse cũng lỗi: $e2');
        return null;
      }
    }
  }

  Future<PlaceResult> _reverseNominatim(double latitude, double longitude) async {
    final res = await _dio.get(
      '$_nominatimBase/reverse',
      queryParameters: {
        'format': 'json',
        'lat': latitude,
        'lon': longitude,
        'accept-language': 'vi',
      },
    );
    final data = (res.data as Map<String, dynamic>?) ?? {};
    final address = (data['address'] as Map<String, dynamic>?) ?? {};

    final street = [
      address['house_number'],
      address['road'] ?? address['pedestrian'],
    ].where((s) => s != null && '$s'.isNotEmpty).join(' ');

    return PlaceResult(
      displayName: (data['display_name'] as String?) ?? '',
      latitude: latitude,
      longitude: longitude,
      street: street.isEmpty ? null : street,
      ward: (address['suburb'] ??
          address['quarter'] ??
          address['city_district'] ??
          address['town'] ??
          address['village']) as String?,
      province: (address['city'] ?? address['state']) as String?,
    );
  }

  Future<PlaceResult> _reversePhoton(double latitude, double longitude) async {
    final res = await _dio.get(
      '$_photonBase/reverse',
      queryParameters: {'lat': latitude, 'lon': longitude, 'lang': 'default'},
    );
    final features = ((res.data as Map?)?['features'] as List? ?? []);
    if (features.isEmpty) {
      throw StateError('Photon không trả về kết quả nào');
    }
    final props = (features.first['properties'] as Map?) ?? {};

    return PlaceResult(
      displayName: _photonDisplayName(props),
      latitude: latitude,
      longitude: longitude,
      street: _photonStreet(props),
      ward: props['district'] as String?,
      province: (props['city'] ?? props['state']) as String?,
    );
  }

  // ─────────── TIỆN ÍCH ───────────

  /// Photon trả về địa chỉ tách rời từng phần, phải tự ghép lại thành một
  /// dòng đầy đủ như display_name của Nominatim.
  String _photonDisplayName(Map props) {
    final parts = [
      _photonStreet(props),
      props['district'],
      props['city'],
      props['state'],
      props['country'],
    ];
    return parts
        .where((p) => p != null && '$p'.trim().isNotEmpty)
        .map((p) => '$p')
        .toSet() // bỏ phần lặp (vd. city và state cùng là "Hà Nội")
        .join(', ');
  }

  void dispose() => _dio.close();

  String? _photonStreet(Map props) {
    final parts = [props['housenumber'], props['street'] ?? props['name']]
        .where((p) => p != null && '$p'.trim().isNotEmpty)
        .map((p) => '$p');
    return parts.isEmpty ? null : parts.join(' ');
  }
}
