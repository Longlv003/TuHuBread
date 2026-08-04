import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart' as getx;
import 'package:tuhubread/l10n/app_localizations.dart';

import '../blocs/address/address_cubit.dart';
import '../models/address.model.dart';
import '../utils/address_label.dart';
import 'address_map_picker_page.dart';

const _addressLabels = ['home', 'company', 'other'];

class AddressFormPage extends StatefulWidget {
  final AddressModel? address;

  const AddressFormPage({super.key, this.address});

  @override
  State<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<AddressFormPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _buildingController;
  late final TextEditingController _gateController;
  late bool _isDefault;
  late String _selectedLabel;
  bool _isSaving = false;

  /// Địa chỉ đầy đủ đã chọn từ màn bản đồ (xem [AddressMapPickerPage]).
  String? _pickedAddress;
  double? _detectedLatitude;
  double? _detectedLongitude;

  bool get _isEditing => widget.address != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.address?.receiverName ?? '');
    _phoneController = TextEditingController(text: widget.address?.receiverPhone ?? '');
    _buildingController = TextEditingController();
    _gateController = TextEditingController();
    _isDefault = widget.address?.isDefault ?? false;
    _selectedLabel = widget.address?.label ?? 'other';
    _pickedAddress = widget.address?.addressDetail;
    _detectedLatitude = widget.address?.latitude;
    _detectedLongitude = widget.address?.longitude;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _buildingController.dispose();
    _gateController.dispose();
    super.dispose();
  }

  /// Mở màn "Chọn địa chỉ" kiểu ShopeeFood (bản đồ + tìm kiếm) — không phụ
  /// thuộc GPS/Geocoder của máy nên vẫn dùng được trên máy ảo/PC.
  Future<void> _pickOnMap() async {
    final result = await getx.Get.to<AddressMapPickerResult>(
      () => AddressMapPickerPage(
        initialLatitude: _detectedLatitude,
        initialLongitude: _detectedLongitude,
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _detectedLatitude = result.latitude;
      _detectedLongitude = result.longitude;
      _pickedAddress = result.displayName ?? result.streetGuess;
    });
  }

  Future<void> _save(AppLocalizations l10n) async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final building = _buildingController.text.trim();
    final gate = _gateController.text.trim();

    if (name.isEmpty || phone.isEmpty || _pickedAddress == null || _pickedAddress!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.emptyFieldsError),
          backgroundColor: const Color(0xFFE74C3C),
        ),
      );
      return;
    }

    final extraParts = [building, gate].where((s) => s.isNotEmpty).join(', ');
    final fullDetail = extraParts.isEmpty ? _pickedAddress! : '$extraParts, ${_pickedAddress!}';

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
    final canSave = !_isSaving &&
        _nameController.text.trim().isNotEmpty &&
        _phoneController.text.trim().isNotEmpty &&
        _pickedAddress != null &&
        _pickedAddress!.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _isEditing ? l10n.addressFormEditTitle : l10n.addressFormAddTitle,
          style: const TextStyle(color: Color(0xFF2C3E50), fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2C3E50)),
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
              onChanged: (_) => setState(() {}),
              decoration: _decoration(l10n.addressReceiverNameHint),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              onChanged: (_) => setState(() {}),
              decoration: _decoration(l10n.addressReceiverPhoneHint),
            ),
            const SizedBox(height: 16),
            // Dòng "Chọn địa chỉ" — bấm để mở màn bản đồ + tìm kiếm, giống
            // ShopeeFood, thay cho 2 dropdown tỉnh/phường + ô đường trước đây.
            InkWell(
              onTap: _pickOnMap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF1EAE1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: Color(0xFFE67E22), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _pickedAddress ?? 'Chọn địa chỉ',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: _pickedAddress == null ? const Color(0xFFBDC3C7) : const Color(0xFF2C3E50),
                          fontWeight: _pickedAddress == null ? FontWeight.normal : FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Color(0xFFBDC3C7)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _buildingController,
              decoration: _decoration('Toà nhà, Số tầng (không bắt buộc)'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _gateController,
              decoration: _decoration('Cổng (không bắt buộc)'),
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
                        color: label == _selectedLabel ? Colors.white : const Color(0xFF7F8C8D),
                      ),
                      selected: label == _selectedLabel,
                      onSelected: (_) => setState(() => _selectedLabel = label),
                      selectedColor: const Color(0xFFE67E22),
                      labelStyle: TextStyle(
                        color: label == _selectedLabel ? Colors.white : const Color(0xFF2C3E50),
                        fontWeight: FontWeight.bold,
                      ),
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: label == _selectedLabel ? const Color(0xFFE67E22) : const Color(0xFFF1EAE1),
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
                onPressed: canSave ? () => _save(l10n) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE67E22),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFF1EAE1),
                  disabledForegroundColor: const Color(0xFFBDC3C7),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(l10n.addressSaveButton, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
