import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../di.dart';
import '../services/location_service.dart';

/// Kết quả trả về khi khách chọn xong vị trí trên bản đồ.
class AddressMapPickerResult {
  final double latitude;
  final double longitude;

  /// Địa chỉ ngắn gọn (số nhà + tên đường) dịch ngược từ toạ độ — ưu tiên
  /// điền vào ô "Số nhà, tên đường" trên form.
  final String? streetGuess;

  /// Địa chỉ đầy đủ dịch ngược — hiện trực tiếp cho khách xem trước khi lưu.
  final String? displayName;

  /// Tên phường/xã, tỉnh/thành dịch ngược — dùng để tự dò chọn sẵn trong 2
  /// dropdown trên form (best-effort, có thể không khớp).
  final String? wardGuess;
  final String? provinceGuess;

  const AddressMapPickerResult({
    required this.latitude,
    required this.longitude,
    this.streetGuess,
    this.displayName,
    this.wardGuess,
    this.provinceGuess,
  });
}

class _PlaceSuggestion {
  final String displayName;
  final double lat;
  final double lng;

  const _PlaceSuggestion({
    required this.displayName,
    required this.lat,
    required this.lng,
  });
}

/// Màn hình chọn vị trí giao hàng kiểu ShopeeFood/Grab: bản đồ với ghim cố
/// định ở giữa màn hình (kéo bản đồ để dời ghim), thanh tìm kiếm địa chỉ,
/// danh sách gợi ý, và nút định vị GPS hiện tại. Dùng OpenStreetMap qua
/// WebView + Nominatim (miễn phí, không cần API key).
class AddressMapPickerPage extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const AddressMapPickerPage({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<AddressMapPickerPage> createState() => _AddressMapPickerPageState();
}

class _AddressMapPickerPageState extends State<AddressMapPickerPage> {
  // Nominatim (OpenStreetMap) yêu cầu bắt buộc phải có User-Agent định danh
  // ứng dụng trong mọi request — thiếu header này request thường bị chặn
  // hoặc trả về rỗng mà không báo lỗi rõ ràng.
  // https://operations.osmfoundation.org/policies/nominatim/
  final _dio = Dio(
    BaseOptions(headers: {'User-Agent': 'TuHuBreadApp/1.0'}),
  );
  final _searchController = TextEditingController();
  final _locationService = getIt<LocationService>();
  InAppWebViewController? _mapController;
  Timer? _searchDebounce;

  bool _isMapLoading = true;
  bool _isResolvingAddress = false;
  bool _isSearching = false;
  bool _isLocating = false;

  double? _centerLat;
  double? _centerLng;
  String? _centerDisplayName;
  String? _centerStreetGuess;
  String? _centerWardGuess;
  String? _centerProvinceGuess;

  List<_PlaceSuggestion> _searchResults = [];
  String? _searchErrorMessage;

  // Mặc định trung tâm Hà Nội — app hiện chỉ giao hàng trong phạm vi này
  // (xem address_form_page.dart).
  static const double _defaultLat = 21.0285;
  static const double _defaultLng = 105.8542;

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    _dio.close();
    super.dispose();
  }

  String get _html {
    final lat = widget.initialLatitude ?? _defaultLat;
    final lng = widget.initialLongitude ?? _defaultLng;
    return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
<style>
  html, body, #map { height: 100%; margin: 0; padding: 0; }
  .leaflet-control-attribution { font-size: 8px; }
</style>
</head>
<body>
<div id="map"></div>
<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
<script>
  const map = L.map('map', { zoomControl: false }).setView([$lat, $lng], 16);
  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    maxZoom: 19,
    attribution: '&copy; OpenStreetMap'
  }).addTo(map);

  function reportCenter() {
    const c = map.getCenter();
    if (window.flutter_inappwebview) {
      window.flutter_inappwebview.callHandler('onCenterChanged', c.lat, c.lng);
    }
  }

  map.on('moveend', reportCenter);

  // Hàm gọi được từ Flutter để dời bản đồ tới 1 toạ độ (chọn từ kết quả tìm
  // kiếm hoặc bấm nút định vị GPS hiện tại).
  window.setMapCenter = function (lat, lng, zoom) {
    map.setView([lat, lng], zoom || 17);
  };

  reportCenter();
</script>
</body>
</html>
''';
  }

  Future<void> _reverseGeocode(double lat, double lng) async {
    setState(() => _isResolvingAddress = true);
    try {
      final res = await _dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'format': 'json',
          'lat': lat,
          'lon': lng,
          'accept-language': 'vi',
        },
      );
      if (!mounted) return;
      final data = res.data as Map<String, dynamic>?;
      final address = (data?['address'] as Map<String, dynamic>?) ?? {};
      setState(() {
        _centerDisplayName = data?['display_name'] as String?;
        _centerStreetGuess = [
          address['house_number'],
          address['road'] ?? address['pedestrian'],
        ].where((s) => s != null && '$s'.isNotEmpty).join(' ');
        _centerWardGuess = (address['suburb'] ?? address['quarter'] ?? address['city_district'] ?? address['town'] ?? address['village']) as String?;
        _centerProvinceGuess = (address['city'] ?? address['state']) as String?;
        _isResolvingAddress = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isResolvingAddress = false);
    }
  }

  void _onCenterChanged(List<dynamic> args) {
    if (!mounted) return;
    final lat = (args[0] as num).toDouble();
    final lng = (args[1] as num).toDouble();
    setState(() {
      _centerLat = lat;
      _centerLng = lng;
    });
    _reverseGeocode(lat, lng);
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().length < 3) {
      setState(() => _searchResults = []);
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 450), () => _search(query.trim()));
  }

  Future<void> _search(String query) async {
    setState(() {
      _isSearching = true;
      _searchErrorMessage = null;
    });
    try {
      final res = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'format': 'json',
          'q': query,
          'countrycodes': 'vn',
          'accept-language': 'vi',
          'limit': 8,
        },
      );
      if (!mounted) return;
      final list = (res.data as List? ?? []);
      setState(() {
        _searchResults = list
            .map((e) => _PlaceSuggestion(
                  displayName: e['display_name'] as String,
                  lat: double.parse(e['lat'] as String),
                  lng: double.parse(e['lon'] as String),
                ))
            .toList();
        _isSearching = false;
      });
    } catch (e) {
      debugPrint('[AddressMapPickerPage] Search failed: $e');
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _searchResults = [];
        _searchErrorMessage = 'Không thể tìm kiếm lúc này, vui lòng kiểm tra kết nối mạng';
      });
    }
  }

  void _selectSuggestion(_PlaceSuggestion s) {
    _searchController.clear();
    setState(() => _searchResults = []);
    FocusScope.of(context).unfocus();
    _mapController?.evaluateJavascript(source: 'window.setMapCenter(${s.lat}, ${s.lng}, 17);');
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);
    final coords = await _locationService.getCurrentCoordinates();
    if (!mounted) return;
    setState(() => _isLocating = false);
    if (coords == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể lấy vị trí hiện tại của máy'),
          backgroundColor: Color(0xFFE74C3C),
        ),
      );
      return;
    }
    _mapController?.evaluateJavascript(
      source: 'window.setMapCenter(${coords.latitude}, ${coords.longitude}, 17);',
    );
  }

  void _confirm() {
    if (_centerLat == null || _centerLng == null) return;
    Navigator.of(context).pop(
      AddressMapPickerResult(
        latitude: _centerLat!,
        longitude: _centerLng!,
        streetGuess: (_centerStreetGuess != null && _centerStreetGuess!.trim().isNotEmpty)
            ? _centerStreetGuess
            : _centerDisplayName,
        displayName: _centerDisplayName,
        wardGuess: _centerWardGuess,
        provinceGuess: _centerProvinceGuess,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Chọn địa chỉ',
          style: TextStyle(color: Color(0xFF2C3E50), fontWeight: FontWeight.bold, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Tìm vị trí',
                hintStyle: const TextStyle(color: Color(0xFFBDC3C7), fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF7F8C8D)),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF7F8C8D)),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchResults = []);
                        },
                      ),
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 300,
            child: Stack(
              alignment: Alignment.center,
              children: [
                InAppWebView(
                  initialData: InAppWebViewInitialData(data: _html),
                  initialSettings: InAppWebViewSettings(javaScriptEnabled: true),
                  onWebViewCreated: (controller) {
                    _mapController = controller;
                    controller.addJavaScriptHandler(
                      handlerName: 'onCenterChanged',
                      callback: (args) {
                        _onCenterChanged(args);
                        return null;
                      },
                    );
                  },
                  onLoadStop: (controller, url) {
                    if (mounted) setState(() => _isMapLoading = false);
                  },
                ),
                if (_isMapLoading)
                  const CircularProgressIndicator(color: Color(0xFFE67E22)),
                // Ghim cố định giữa màn hình — bản đồ di chuyển bên dưới, ghim
                // luôn đứng yên tại tâm, giống Grab/ShopeeFood.
                IgnorePointer(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 28),
                    child: Icon(
                      Icons.location_on_rounded,
                      color: const Color(0xFFE67E22),
                      size: 40,
                      shadows: [Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))],
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: FloatingActionButton.small(
                    heroTag: 'currentLocationBtn',
                    backgroundColor: Colors.white,
                    onPressed: _isLocating ? null : _useCurrentLocation,
                    child: _isLocating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE67E22)),
                          )
                        : const Icon(Icons.my_location_rounded, color: Color(0xFFE67E22), size: 20),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _searchController.text.trim().length >= 3
                ? _buildSearchResultsList()
                : _buildCurrentPinPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultsList() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFE67E22)));
    }
    if (_searchErrorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            _searchErrorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFE74C3C), fontSize: 13),
          ),
        ),
      );
    }
    if (_searchResults.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Không tìm thấy địa điểm phù hợp',
            style: TextStyle(color: Color(0xFFBDC3C7), fontSize: 13),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _searchResults.length,
      separatorBuilder: (c, i) => const Divider(height: 1, color: Color(0xFFF1EAE1)),
      itemBuilder: (context, idx) {
        final s = _searchResults[idx];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.location_on_outlined, color: Color(0xFF7F8C8D)),
          title: Text(
            s.displayName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: Color(0xFF2C3E50)),
          ),
          onTap: () => _selectSuggestion(s),
        );
      },
    );
  }

  Widget _buildCurrentPinPanel() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        const Text(
          'Vị trí đã ghim',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF7F8C8D)),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF1EAE1)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_rounded, color: Color(0xFFE67E22)),
              const SizedBox(width: 10),
              Expanded(
                child: _isResolvingAddress
                    ? const Text(
                        'Đang xác định địa chỉ...',
                        style: TextStyle(fontSize: 13, color: Color(0xFF7F8C8D)),
                      )
                    : Text(
                        _centerDisplayName ?? 'Kéo bản đồ để ghim vị trí giao hàng',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50)),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _centerLat == null ? null : _confirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE67E22),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Xác nhận vị trí này', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
