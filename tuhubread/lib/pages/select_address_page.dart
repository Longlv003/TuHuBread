import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart' as getx;
import 'package:tuhubread/l10n/app_localizations.dart';

import '../blocs/address/address_cubit.dart';
import '../blocs/address/address_state.dart';
import '../di.dart';
import '../models/address.model.dart';
import '../utils/address_label.dart';
import 'address_form_page.dart';

/// Màn hình chọn địa chỉ giao hàng kiểu ShopeeFood: địa chỉ đang chọn được
/// ghim nổi bật phía trên, danh sách địa chỉ đã lưu ở dưới, kèm ô tìm kiếm
/// cục bộ và lối tắt lấy vị trí hiện tại (GPS).
class SelectAddressPage extends StatelessWidget {
  final String? selectedAddressId;

  const SelectAddressPage({super.key, this.selectedAddressId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AddressCubit>(
      create: (_) => getIt<AddressCubit>()..loadMyAddresses(),
      child: _SelectAddressContent(selectedAddressId: selectedAddressId),
    );
  }
}

class _SelectAddressContent extends StatefulWidget {
  final String? selectedAddressId;

  const _SelectAddressContent({this.selectedAddressId});

  @override
  State<_SelectAddressContent> createState() => _SelectAddressContentState();
}

class _SelectAddressContentState extends State<_SelectAddressContent> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openAddressForm(
    BuildContext context, {
    AddressModel? address,
  }) async {
    final cubit = context.read<AddressCubit>();
    await getx.Get.to(
      () => BlocProvider.value(
        value: cubit,
        child: AddressFormPage(address: address),
      ),
      routeName: '/select-address/address-form',
      preventDuplicates: false,
    );
  }

  bool _matchesQuery(AddressModel address) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return address.receiverName.toLowerCase().contains(q) ||
        address.addressDetail.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.selectAddressTitle,
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
      body: BlocBuilder<AddressCubit, AddressState>(
        builder: (context, state) {
          if (state is AddressLoading || state is AddressInitial) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE67E22)),
            );
          }

          final addresses = state is AddressLoaded
              ? state.addresses
              : <AddressModel>[];
          final selected = addresses.where(
            (a) => a.id == widget.selectedAddressId,
          );
          final selectedAddress = selected.isEmpty ? null : selected.first;
          final otherAddresses = addresses
              .where((a) => a.id != widget.selectedAddressId)
              .where(_matchesQuery)
              .toList();

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: l10n.selectAddressSearchHint,
                        hintStyle: const TextStyle(
                          color: Color(0xFFBDC3C7),
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF7F8C8D),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFF1EAE1),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFF1EAE1),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (selectedAddress != null) ...[
                      _PinnedAddressCard(
                        address: selectedAddress,
                        l10n: l10n,
                        onEdit: () =>
                            _openAddressForm(context, address: selectedAddress),
                        onTap: () => getx.Get.back(result: selectedAddress),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _UseCurrentLocationRow(
                      label: l10n.addressUseCurrentLocation,
                      onTap: () => _openAddressForm(context),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.selectAddressSavedTitle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7F8C8D),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (otherAddresses.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            l10n.selectAddressEmpty,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFFBDC3C7),
                            ),
                          ),
                        ),
                      )
                    else
                      ...otherAddresses.map(
                        (address) => _SavedAddressRow(
                          address: address,
                          l10n: l10n,
                          onTap: () => getx.Get.back(result: address),
                          onEdit: () =>
                              _openAddressForm(context, address: address),
                        ),
                      ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openAddressForm(context),
                      icon: const Icon(Icons.add_rounded, color: Colors.white),
                      label: Text(
                        l10n.addressAddButton,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE67E22),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PinnedAddressCard extends StatelessWidget {
  final AddressModel address;
  final AppLocalizations l10n;
  final VoidCallback onEdit;
  final VoidCallback onTap;

  const _PinnedAddressCard({
    required this.address,
    required this.l10n,
    required this.onEdit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFDF0E5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE67E22), width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.location_on_rounded, color: Color(0xFFE67E22)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    address.addressDetail,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${address.receiverName} · ${address.receiverPhone}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF7F8C8D),
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onEdit,
              child: Text(
                l10n.addressEditAction,
                style: const TextStyle(fontSize: 12, color: Color(0xFF2980B9)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UseCurrentLocationRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _UseCurrentLocationRow({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            const Icon(
              Icons.my_location_rounded,
              size: 18,
              color: Color(0xFFE67E22),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE67E22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedAddressRow extends StatelessWidget {
  final AddressModel address;
  final AppLocalizations l10n;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const _SavedAddressRow({
    required this.address,
    required this.l10n,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF1EAE1))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              addressLabelIcon(address.label),
              size: 20,
              color: const Color(0xFF2C3E50),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        addressLabelText(l10n, address.label),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      if (address.isDefault) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDF0E5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            l10n.addressDefaultLabel,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE67E22),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address.addressDetail,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF7F8C8D),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${address.receiverName}   ${address.receiverPhone}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFBDC3C7),
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onEdit,
              child: Text(
                l10n.addressEditAction,
                style: const TextStyle(fontSize: 12, color: Color(0xFF2980B9)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
