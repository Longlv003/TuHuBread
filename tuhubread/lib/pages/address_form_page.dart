import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart' as getx;
import 'package:tuhubread/l10n/app_localizations.dart';

import '../blocs/address/address_cubit.dart';
import '../di.dart';
import '../models/address.model.dart';
import '../models/province.model.dart';
import '../models/ward.model.dart';
import '../services/location_service.dart';
import '../services/vietnam_address_service.dart';
import '../utils/address_label.dart';

const _addressLabels = ['home', 'company', 'other'];

class AddressFormPage extends StatefulWidget {
  final AddressModel? address;

  const AddressFormPage({super.key, this.address});

  @override
  State<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<AddressFormPage> {
  final _addressService = getIt<VietnamAddressService>();
  final _locationService = getIt<LocationService>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _streetController;
  late bool _isDefault;
  late String _selectedLabel;
  bool _isSaving = false;
  bool _isDetectingLocation = false;
  double? _detectedLatitude;
  double? _detectedLongitude;

  List<ProvinceModel> _provinces = [];
  List<WardModel> _wards = [];
  ProvinceModel? _selectedProvince;
  WardModel? _selectedWard;
  bool _isLoadingProvinces = true;
  bool _isLoadingWards = false;

  bool get _isEditing => widget.address != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.address?.receiverName ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.address?.receiverPhone ?? '',
    );
    _streetController = TextEditingController(
      text: widget.address?.addressDetail ?? '',
    );
    _isDefault = widget.address?.isDefault ?? false;
    _selectedLabel = widget.address?.label ?? 'other';
    _loadProvinces();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  Future<void> _loadProvinces() async {
    final provinces = await _addressService.fetchProvinces();
    if (!mounted) return;
    setState(() {
      _provinces = provinces;
      _isLoadingProvinces = false;
    });
  }

  Future<void> _onProvinceChanged(ProvinceModel? province) async {
    setState(() {
      _selectedProvince = province;
      _selectedWard = null;
      _wards = [];
      _isLoadingWards = province != null;
    });

    if (province == null) return;

    final wards = await _addressService.fetchWardsByProvince(province.code);
    if (!mounted) return;
    setState(() {
      _wards = wards;
      _isLoadingWards = false;
    });
  }

  String _normalize(String s) => s
      .toLowerCase()
      .replaceAll(
        RegExp(r'^(thành phố|tỉnh|phường|xã|thị trấn|quận|huyện)\s+'),
        '',
      )
      .trim();

  T? _bestMatch<T>(String? target, List<T> options, String Function(T) name) {
    if (target == null || target.isEmpty) return null;
    final normalizedTarget = _normalize(target);
    for (final option in options) {
      final normalizedName = _normalize(name(option));
      if (normalizedName == normalizedTarget ||
          normalizedName.contains(normalizedTarget) ||
          normalizedTarget.contains(normalizedName)) {
        return option;
      }
    }
    return null;
  }

  Future<void> _useCurrentLocation(AppLocalizations l10n) async {
    setState(() => _isDetectingLocation = true);
    try {
      final result = await _locationService.getCurrentAddress();
      if (!mounted) return;

      _detectedLatitude = result.latitude;
      _detectedLongitude = result.longitude;
      _streetController.text = result.street ?? result.fullAddress;

      final matchedProvince = _bestMatch(
        result.provinceName,
        _provinces,
        (p) => p.name,
      );
      if (matchedProvince != null) {
        await _onProvinceChanged(matchedProvince);
        if (!mounted) return;
        final matchedWard = _bestMatch(result.wardName, _wards, (w) => w.name);
        if (matchedWard != null) {
          setState(() => _selectedWard = matchedWard);
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.addressLocationDetected),
          backgroundColor: const Color(0xFF27AE60),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on LocationException catch (e) {
      if (!mounted) return;
      final message = switch (e.reason) {
        LocationFailureReason.serviceDisabled =>
          l10n.addressLocationServiceDisabled,
        LocationFailureReason.permissionDenied =>
          l10n.addressLocationPermissionDenied,
        LocationFailureReason.permissionDeniedForever =>
          l10n.addressLocationPermissionDeniedForever,
        LocationFailureReason.geocodeFailed => l10n.addressLocationFailed,
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFE74C3C),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isDetectingLocation = false);
    }
  }

  Future<void> _save(AppLocalizations l10n) async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final street = _streetController.text.trim();

    if (name.isEmpty ||
        phone.isEmpty ||
        street.isEmpty ||
        _selectedProvince == null ||
        _selectedWard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.emptyFieldsError),
          backgroundColor: const Color(0xFFE74C3C),
        ),
      );
      return;
    }

    final fullDetail =
        '$street, ${_selectedWard!.name}, ${_selectedProvince!.name}';

    setState(() => _isSaving = true);

    final cubit = context.read<AddressCubit>();
    final success = _isEditing
        ? await cubit.editAddress(
            id: widget.address!.id,
            receiverName: name,
            receiverPhone: phone,
            addressDetail: fullDetail,
            isDefault: _isDefault,
            label: _selectedLabel,
            latitude: _detectedLatitude,
            longitude: _detectedLongitude,
          )
        : await cubit.addAddress(
            receiverName: name,
            receiverPhone: phone,
            addressDetail: fullDetail,
            isDefault: _isDefault,
            label: _selectedLabel,
            latitude: _detectedLatitude,
            longitude: _detectedLongitude,
          );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      getx.Get.back();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.addressSaveError),
          backgroundColor: const Color(0xFFE74C3C),
        ),
      );
    }
  }

  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFF1EAE1)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _isEditing ? l10n.addressFormEditTitle : l10n.addressFormAddTitle,
          style: const TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF2C3E50),
          ),
          onPressed: () => getx.Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: _decoration(l10n.addressReceiverNameHint),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: _decoration(l10n.addressReceiverPhoneHint),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isDetectingLocation
                    ? null
                    : () => _useCurrentLocation(l10n),
                icon: _isDetectingLocation
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFE67E22),
                        ),
                      )
                    : const Icon(
                        Icons.my_location_rounded,
                        size: 18,
                        color: Color(0xFFE67E22),
                      ),
                label: Text(
                  _isDetectingLocation
                      ? l10n.addressLocationDetecting
                      : l10n.addressUseCurrentLocation,
                  style: const TextStyle(color: Color(0xFFE67E22)),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE67E22)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _isLoadingProvinces
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: CircularProgressIndicator(
                        color: Color(0xFFE67E22),
                      ),
                    ),
                  )
                : DropdownButtonFormField<ProvinceModel>(
                    initialValue: _selectedProvince,
                    decoration: _decoration(l10n.addressProvinceHint),
                    items: _provinces
                        .map(
                          (p) =>
                              DropdownMenuItem(value: p, child: Text(p.name)),
                        )
                        .toList(),
                    onChanged: _onProvinceChanged,
                  ),
            const SizedBox(height: 16),
            if (_isLoadingWards)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: CircularProgressIndicator(color: Color(0xFFE67E22)),
                ),
              )
            else
              DropdownButtonFormField<WardModel>(
                initialValue: _selectedWard,
                decoration: _decoration(l10n.addressWardHint),
                items: _wards
                    .map((w) => DropdownMenuItem(value: w, child: Text(w.name)))
                    .toList(),
                onChanged: _selectedProvince == null
                    ? null
                    : (w) => setState(() => _selectedWard = w),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _streetController,
              maxLines: 2,
              decoration: _decoration(l10n.addressStreetHint),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: _addressLabels
                  .map(
                    (label) => ChoiceChip(
                      label: Text(addressLabelText(l10n, label)),
                      avatar: Icon(
                        addressLabelIcon(label),
                        size: 16,
                        color: label == _selectedLabel
                            ? Colors.white
                            : const Color(0xFF7F8C8D),
                      ),
                      selected: label == _selectedLabel,
                      onSelected: (_) => setState(() => _selectedLabel = label),
                      selectedColor: const Color(0xFFE67E22),
                      labelStyle: TextStyle(
                        color: label == _selectedLabel
                            ? Colors.white
                            : const Color(0xFF2C3E50),
                        fontWeight: FontWeight.bold,
                      ),
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: label == _selectedLabel
                            ? const Color(0xFFE67E22)
                            : const Color(0xFFF1EAE1),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _isDefault,
              onChanged: (v) => setState(() => _isDefault = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: const Color(0xFFE67E22),
              title: Text(
                l10n.addressSetDefaultLabel,
                style: const TextStyle(fontSize: 14, color: Color(0xFF2C3E50)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : () => _save(l10n),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE67E22),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        l10n.addressSaveButton,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
