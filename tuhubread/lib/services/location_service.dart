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

  void setDeliveryCoordinates(double? latitude, double? longitude) {
    _deliveryCoordinates = (latitude != null && longitude != null)
        ? (latitude: latitude, longitude: longitude)
        : null;
  }

  /// Toạ độ dùng để tìm "Cửa hàng gần bạn": ưu tiên địa chỉ giao hàng đang
  /// chọn, không có thì mới lấy GPS (đã tự lùi về vị trí cũ nếu GPS lỗi).
  Future<({double latitude, double longitude})?> resolveNearbyCoordinates() {
    if (_deliveryCoordinates != null) {
      return Future.value(_deliveryCoordinates);
    }
    return getCurrentCoordinates();
  }

  /// Trả về null nếu không có quyền/không bật GPS thay vì throw, vì đây là
  /// tính năng "có thì tốt" (tìm cửa hàng gần trên trang chủ), không nên làm
  /// phiền người dùng bằng dialog xin quyền ngay khi vừa mở app.
  ///
  /// Khi lần lấy này thất bại nhưng trước đó đã từng lấy được, trả về vị trí
  /// cũ thay vì null (xem [_lastKnownCoordinates]).
  Future<({double latitude, double longitude})?> getCurrentCoordinates() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return _lastKnownCoordinates;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return _lastKnownCoordinates;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 6),
        ),
      );
      _lastKnownCoordinates = (
        latitude: position.latitude,
        longitude: position.longitude,
      );
      return _lastKnownCoordinates;
    } catch (_) {
      // Bao gồm cả TimeoutException khi máy bắt GPS chậm/không có tín hiệu.
      return _lastKnownCoordinates;
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
      throw const LocationException(LocationFailureReason.permissionDeniedForever);
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
