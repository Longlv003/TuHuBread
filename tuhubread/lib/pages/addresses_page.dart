import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart' as getx;
import 'package:tuhubread/l10n/app_localizations.dart';

import '../blocs/address/address_cubit.dart';
import '../blocs/address/address_state.dart';
import '../di.dart';
import '../models/address.model.dart';
import 'address_form_page.dart';

class AddressesPage extends StatelessWidget {
  const AddressesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AddressCubit>(
      create: (_) => getIt<AddressCubit>()..loadMyAddresses(),
      child: const _AddressesContent(),
    );
  }
}

class _AddressesContent extends StatelessWidget {
  const _AddressesContent();

  Future<void> _openForm(BuildContext context, {AddressModel? address}) async {
    final cubit = context.read<AddressCubit>();
    await getx.Get.to(
      () => BlocProvider.value(
        value: cubit,
        child: AddressFormPage(address: address),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, AppLocalizations l10n, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.addressDeleteConfirmTitle),
        content: Text(l10n.addressDeleteConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.profileCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.addressDeleteAction, style: const TextStyle(color: Color(0xFFC0392B))),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await context.read<AddressCubit>().removeAddress(id);
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.addressDeleteError), backgroundColor: const Color(0xFFE74C3C)),
        );
      }
    }
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
          l10n.addressesTitle,
          style: const TextStyle(color: Color(0xFF2C3E50), fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2C3E50)),
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

          if (state is AddressFailure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 54, color: Color(0xFFE74C3C)),
                    const SizedBox(height: 16),
                    Text(
                      state.error,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF7F8C8D)),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => context.read<AddressCubit>().loadMyAddresses(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE67E22),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(l10n.retryButton),
                    ),
                  ],
                ),
              ),
            );
          }

          final addresses = state is AddressLoaded ? state.addresses : <AddressModel>[];

          return Column(
            children: [
              Expanded(
                child: addresses.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.location_off_outlined, size: 64, color: Color(0xFFBDC3C7)),
                              const SizedBox(height: 16),
                              Text(
                                l10n.addressesEmptyTitle,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l10n.addressesEmptySubtitle,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF7F8C8D)),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: addresses.length,
                        separatorBuilder: (c, i) => const SizedBox(height: 12),
                        itemBuilder: (context, idx) {
                          final address = addresses[idx];
                          return _AddressCard(
                            address: address,
                            l10n: l10n,
                            onEdit: () => _openForm(context, address: address),
                            onDelete: () => _confirmDelete(context, l10n, address.id),
                            onSetDefault: () => context.read<AddressCubit>().setDefault(address.id),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openForm(context),
                    icon: const Icon(Icons.add_rounded, color: Colors.white),
                    label: Text(
                      l10n.addressAddButton,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE67E22),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
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

class _AddressCard extends StatelessWidget {
  final AddressModel address;
  final AppLocalizations l10n;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  const _AddressCard({
    required this.address,
    required this.l10n,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: address.isDefault ? const Color(0xFFE67E22) : const Color(0xFFF1EAE1),
          width: address.isDefault ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  address.receiverName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ),
              if (address.isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDF0E5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    l10n.addressDefaultLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE67E22),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            address.receiverPhone,
            style: const TextStyle(fontSize: 13, color: Color(0xFF7F8C8D)),
          ),
          const SizedBox(height: 4),
          Text(
            address.addressDetail,
            style: const TextStyle(fontSize: 13, color: Color(0xFF34495E)),
          ),
          const Divider(height: 20, color: Color(0xFFF1EAE1)),
          Row(
            children: [
              if (!address.isDefault)
                TextButton(
                  onPressed: onSetDefault,
                  child: Text(
                    l10n.addressSetDefaultAction,
                    style: const TextStyle(fontSize: 12, color: Color(0xFFE67E22)),
                  ),
                ),
              const Spacer(),
              TextButton(
                onPressed: onEdit,
                child: Text(
                  l10n.addressEditAction,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF2C3E50)),
                ),
              ),
              TextButton(
                onPressed: onDelete,
                child: Text(
                  l10n.addressDeleteAction,
                  style: const TextStyle(fontSize: 12, color: Color(0xFFC0392B)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
