import 'package:geolocator/geolocator.dart';

/// Lấy vị trí GPS thô của thiết bị. Dịch ngược toạ độ ra địa chỉ text (khi
/// cần) được thực hiện qua Nominatim trong [AddressMapPickerPage] thay vì
/// Geocoder gốc của hệ điều hành — Geocoder gốc thường không hoạt động trên
/// máy ảo/emulator, còn Nominatim chỉ cần có mạng.
class LocationService {
  /// Trả về null nếu không có quyền/không bật GPS thay vì throw, vì đây là
  /// tính năng "có thì tốt" (tìm cửa hàng gần trên trang chủ), không nên
  /// chặn màn hình khi bị từ chối quyền hoặc thiết bị bắt GPS chậm.
  Future<({double latitude, double longitude})?> getCurrentCoordinates() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 6),
        ),
      );
      return (latitude: position.latitude, longitude: position.longitude);
    } catch (_) {
      // Bao gồm cả TimeoutException khi máy bắt GPS chậm/không có tín hiệu —
      // trả về null để màn hình gọi vẫn hoạt động bình thường.
      return null;
    }
  }
}
