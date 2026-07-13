import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

enum LocationFailureReason {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  geocodeFailed,
}

class LocationException implements Exception {
  final LocationFailureReason reason;
  const LocationException(this.reason);
}

/// Kết quả dò vị trí GPS + dịch ngược (reverse geocoding) ra địa chỉ text.
/// [provinceName]/[wardName] là tên thô từ hệ điều hành, dùng để dò khớp
/// (best-effort) với danh sách tỉnh/phường lấy từ [VietnamAddressService].
class LocationResult {
  final double latitude;
  final double longitude;
  final String? street;
  final String? wardName;
  final String? provinceName;
  final String fullAddress;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    this.street,
    this.wardName,
    this.provinceName,
    required this.fullAddress,
  });
}

/// Lấy vị trí GPS hiện tại và dịch ngược ra địa chỉ text — dùng
/// `geocoding`, dựa trên bộ dịch địa chỉ sẵn có của hệ điều hành nên
/// không cần API key.
class LocationService {
  Future<LocationResult> getCurrentAddress() async {
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

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isEmpty) {
        throw const LocationException(LocationFailureReason.geocodeFailed);
      }

      final p = placemarks.first;
      final street = [
        p.street,
        p.subLocality,
      ].where((s) => s != null && s.isNotEmpty).join(', ');
      final fullAddress = [
        street,
        p.subAdministrativeArea,
        p.administrativeArea,
      ].where((s) => s != null && s.isNotEmpty).join(', ');

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        street: street.isEmpty ? null : street,
        wardName: p.subLocality,
        provinceName: p.administrativeArea,
        fullAddress: fullAddress.isEmpty
            ? '${position.latitude}, ${position.longitude}'
            : fullAddress,
      );
    } on LocationException {
      rethrow;
    } catch (_) {
      throw const LocationException(LocationFailureReason.geocodeFailed);
    }
  }
}
