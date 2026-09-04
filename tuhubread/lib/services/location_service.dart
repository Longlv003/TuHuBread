import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:geolocator/geolocator.dart';

enum LocationFailureReason {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
}

class LocationException implements Exception {
  final LocationFailureReason reason;
  const LocationException(this.reason);
}

/// Lấy vị trí GPS thô của thiết bị. Dịch ngược toạ độ ra địa chỉ text (khi
/// cần) được thực hiện qua Nominatim trong [AddressMapPickerPage] thay vì
/// Geocoder gốc của hệ điều hành — Geocoder gốc thường không hoạt động trên
/// máy ảo/emulator, còn Nominatim chỉ cần có mạng.
class LocationService {
  /// Toạ độ lấy được thành công gần nhất trong phiên chạy hiện tại.
  ///
  /// GPS thỉnh thoảng thất bại tạm thời (quá thời gian chờ, mất tín hiệu trong
  /// nhà, máy ảo). Nếu những lúc đó trả về null, màn hình Home sẽ gọi API
  /// KHÔNG kèm toạ độ — backend hiểu là "không biết khách ở đâu" nên bỏ luôn
  /// bộ lọc bán kính và trả về TẤT CẢ cửa hàng, kể cả cách hàng trăm km. Giữ
  /// lại vị trí cũ để dùng tạm hợp lý hơn nhiều: người dùng hiếm khi di chuyển
  /// xa trong vài phút giữa 2 lần mở trang chủ.
  ({double latitude, double longitude})? _lastKnownCoordinates;

  ({double latitude, double longitude})? get lastKnownCoordinates =>
      _lastKnownCoordinates;

  /// Toạ độ địa chỉ giao hàng khách đang chọn.
  ///
  /// Giữ ở đây (service singleton) thay vì trong HomeCubit vì HomeCubit được
  /// đăng ký dạng factory — mỗi lần màn hình chính dựng lại sẽ tạo cubit mới
  /// và mất sạch state, khiến trang chủ quay về dùng GPS rồi hiện lại toàn bộ
  /// cửa hàng.
  ({double latitude, double longitude})? _deliveryCoordinates;

  ({double latitude, double longitude})? get deliveryCoordinates =>
      _deliveryCoordinates;

  /// Khách vừa CHỦ ĐỘNG đổi địa chỉ giao hàng -> "Cửa hàng gần bạn" phải theo
  /// địa chỉ đó chứ không theo chỗ đang đứng. Ngược lại (mở app bình thường)
  /// thì ưu tiên GPS.
  bool _preferDeliveryOverGps = false;

  void setDeliveryCoordinates(
    double? latitude,
    double? longitude, {
    bool preferOverGps = false,
  }) {
    _deliveryCoordinates = (latitude != null && longitude != null)
        ? (latitude: latitude, longitude: longitude)
        : null;
    _preferDeliveryOverGps = preferOverGps && _deliveryCoordinates != null;
  }

  /// Xoá toạ độ địa chỉ giao hàng đã "ghim" và cờ ưu tiên nó hơn GPS.
  ///
  /// [LocationService] là singleton sống suốt vòng đời app (đăng ký qua
  /// GetIt), nên nếu không gọi hàm này khi đăng xuất, tài khoản đăng nhập kế
  /// tiếp trong CÙNG phiên chạy app sẽ vẫn thấy "Cửa hàng gần bạn" tính theo
  /// địa chỉ giao hàng của tài khoản TRƯỚC ĐÓ thay vì vị trí GPS thật — trông
  /// như thể vị trí bị "khoá cứng" vào tài khoản đầu tiên đăng nhập trên máy.
  /// Không xoá [_lastKnownCoordinates] — đó là toạ độ GPS thô của thiết bị,
  /// không gắn với tài khoản nào, giữ lại giúp lần tải trang chủ kế tiếp có
  /// ngay dữ liệu để hiện trong lúc chờ GPS tươi.
  void resetDeliveryPreference() {
    _deliveryCoordinates = null;
    _preferDeliveryOverGps = false;
  }

  /// Toạ độ có sẵn NGAY LẬP TỨC (không phải chờ GPS) để trang chủ hiện dữ
  /// liệu trước, rồi mới tải lại bằng GPS tươi sau. Null nếu chưa có gì.
  ({double latitude, double longitude})? get quickCoordinates {
    if (_preferDeliveryOverGps) return _deliveryCoordinates;
    return _lastKnownCoordinates ?? _deliveryCoordinates;
  }

  /// Toạ độ chính xác dùng để tìm "Cửa hàng gần bạn".
  ///
  /// Mở app -> lấy GPS hiện tại (giống Grab/ShopeeFood: hiện quán quanh chỗ
  /// đang đứng). Không lấy được GPS mới lùi về địa chỉ giao hàng. Riêng khi
  /// khách vừa tự tay đổi địa chỉ thì dùng thẳng địa chỉ đó.
  Future<({double latitude, double longitude})?>
  resolveNearbyCoordinates() async {
    if (_preferDeliveryOverGps && _deliveryCoordinates != null) {
      return _deliveryCoordinates;
    }
    return await getCurrentCoordinates() ?? _deliveryCoordinates;
  }

  /// Khoảng cách gần đúng (km) giữa 2 toạ độ — đủ dùng để biết vị trí có
  /// "đổi đáng kể" hay không, không cần chính xác tới mét.
  static double distanceKm(
    ({double latitude, double longitude}) a,
    ({double latitude, double longitude}) b,
  ) {
    const kmPerDegree = 111.0;
    final dLat = (a.latitude - b.latitude) * kmPerDegree;
    final dLng =
        (a.longitude - b.longitude) *
        kmPerDegree *
        math.cos(a.latitude * math.pi / 180);
    return math.sqrt(dLat * dLat + dLng * dLng);
  }

  /// Trả về null nếu không có quyền/không bật GPS thay vì throw, vì đây là
  /// tính năng "có thì tốt" (tìm cửa hàng gần trên trang chủ), không nên làm
  /// phiền người dùng bằng dialog xin quyền ngay khi vừa mở app.
  ///
  /// Khi lần lấy này thất bại nhưng trước đó đã từng lấy được, trả về vị trí
  /// cũ thay vì null (xem [_lastKnownCoordinates]).
  Future<({double latitude, double longitude})?> getCurrentCoordinates() async {
    try {
      // TODO(debug): log tạm để chẩn đoán vì sao vị trí đôi khi không lấy
      // được ngay lần đầu mở app — xoá khi đã xác nhận ổn định.
      if (!await Geolocator.isLocationServiceEnabled()) {
        debugPrint('[LocationService] location service (GPS) đang TẮT trên thiết bị');
        return _lastKnownCoordinates;
      }

      var permission = await Geolocator.checkPermission();
      debugPrint('[LocationService] permission hiện tại: $permission');
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        debugPrint('[LocationService] permission sau khi xin: $permission');
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return _lastKnownCoordinates;
      }

      return await _fetchPosition(const Duration(seconds: 6));
    } catch (e) {
      // Bao gồm cả TimeoutException khi máy bắt GPS chậm/không có tín hiệu.
      debugPrint('[LocationService] getCurrentCoordinates lỗi: $e');
      return _lastKnownCoordinates;
    }
  }

  /// Lấy toạ độ GPS thô, với 1 lần thử lại nếu đây là lần bắt tín hiệu ĐẦU
  /// TIÊN trong phiên chạy (chưa có [_lastKnownCoordinates] để dùng tạm) và
  /// lần đầu bị timeout. Các lần sau đã có toạ độ cũ để dùng tạm nên không
  /// cần thử lại, tránh làm các lần load thường ngày chậm thêm vô ích.
  Future<({double latitude, double longitude})?> _fetchPosition(
    Duration timeLimit, {
    bool isRetry = false,
  }) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: timeLimit,
        ),
      );
      debugPrint('[LocationService] GPS fix OK: ${position.latitude}, ${position.longitude}');
      _lastKnownCoordinates = (
        latitude: position.latitude,
        longitude: position.longitude,
      );
      return _lastKnownCoordinates;
    } on TimeoutException {
      debugPrint('[LocationService] getCurrentPosition timeout (isRetry=$isRetry, limit=${timeLimit.inSeconds}s)');
      if (!isRetry && _lastKnownCoordinates == null) {
        return await _fetchPosition(timeLimit, isRetry: true);
      }
      rethrow;
    }
  }

  /// Dùng khi người dùng CHỦ ĐỘNG bấm nút "Vị trí hiện tại" (khác
  /// [getCurrentCoordinates] chạy ngầm, im lặng khi thất bại) — throw lỗi cụ
  /// thể để màn hình gọi biết chính xác lý do và hướng dẫn xử lý (bật định vị
  /// máy / vào Cài đặt cấp lại quyền), thay vì thất bại trong im lặng khiến
  /// người dùng tưởng app "không hỏi gì cả".
  Future<({double latitude, double longitude})> requestCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException(LocationFailureReason.serviceDisabled);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationException(LocationFailureReason.permissionDenied);
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        LocationFailureReason.permissionDeniedForever,
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      _lastKnownCoordinates = (
        latitude: position.latitude,
        longitude: position.longitude,
      );
      return _lastKnownCoordinates!;
    } catch (_) {
      throw const LocationException(LocationFailureReason.timeout);
    }
  }
}
