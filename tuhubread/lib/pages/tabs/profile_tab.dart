import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart' as getx;
import 'package:tuhubread/l10n/app_localizations.dart';
import '../../blocs/auth/auth_cubit.dart';
import '../../models/user.model.dart';
import '../addresses_page.dart';
import '../change_password_page.dart';
import '../edit_profile_page.dart';
import '../help_center_page.dart';
import '../my_vouchers_page.dart';
import '../settings_page.dart';

class ProfileTab extends StatelessWidget {
  final UserModel user;

  const ProfileTab({super.key, required this.user});

  Future<void> _confirmLogout(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.profileLogoutConfirmTitle),
        content: Text(l10n.profileLogoutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.profileCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              l10n.logoutButton,
              style: const TextStyle(color: Color(0xFFC0392B), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<AuthCubit>().handleLogout();
    }
  }

  void _handleChangePassword(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isPasswordUser = FirebaseAuth.instance.currentUser?.providerData
            .any((p) => p.providerId == 'password') ??
        false;

    if (!isPasswordUser) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.changePasswordNotApplicable)),
      );
      return;
    }

    getx.Get.to(() => const ChangePasswordPage());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProfileHeader(user: user, onEdit: () => getx.Get.to(() => EditProfilePage(user: user))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              children: [
                _ProfileMenuGroup(
                  items: [
                    _ProfileMenuItem(
                      icon: Icons.edit_outlined,
                      color: const Color(0xFFE67E22),
                      title: l10n.profileEditProfile,
                      subtitle: l10n.profileEditProfileSub,
                      onTap: () => getx.Get.to(() => EditProfilePage(user: user)),
                    ),
                    _ProfileMenuItem(
                      icon: Icons.location_on_outlined,
                      color: const Color(0xFF16A085),
                      title: l10n.profileAddresses,
                      subtitle: l10n.profileAddressesSub,
                      onTap: () => getx.Get.to(() => const AddressesPage()),
                    ),
                    _ProfileMenuItem(
                      icon: Icons.confirmation_number_outlined,
                      color: const Color(0xFFE91E63),
                      title: l10n.profileMyVouchers,
                      subtitle: l10n.profileMyVouchersSub,
                      onTap: () => getx.Get.to(() => const MyVouchersPage()),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _ProfileMenuGroup(
                  items: [
                    _ProfileMenuItem(
                      icon: Icons.lock_outline_rounded,
                      color: const Color(0xFF8E44AD),
                      title: l10n.profileChangePassword,
                      subtitle: l10n.profileChangePasswordSub,
                      onTap: () => _handleChangePassword(context),
                    ),
                    _ProfileMenuItem(
                      icon: Icons.settings_outlined,
                      color: const Color(0xFF2980B9),
                      title: l10n.profileSettings,
                      subtitle: l10n.profileSettingsSub,
                      onTap: () => getx.Get.to(() => const SettingsPage()),
                    ),
                    _ProfileMenuItem(
                      icon: Icons.help_outline_rounded,
                      color: const Color(0xFF27AE60),
                      title: l10n.profileHelpCenter,
                      subtitle: l10n.profileHelpCenterSub,
                      onTap: () => getx.Get.to(() => const HelpCenterPage()),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmLogout(context),
                    icon: const Icon(Icons.logout_rounded, color: Color(0xFFC0392B), size: 20),
                    label: Text(
                      l10n.logoutButton,
                      style: const TextStyle(color: Color(0xFFC0392B), fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFFFDECEA),
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserModel user;
  final VoidCallback onEdit;

  const _ProfileHeader({required this.user, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasAvatar = user.avatarUrl != null && user.avatarUrl!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF39C12), Color(0xFFE67E22)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white.withOpacity(0.25),
                  backgroundImage: hasAvatar ? NetworkImage(user.avatarUrl!) : null,
                  child: !hasAvatar
                      ? const Icon(Icons.person_rounded, size: 38, color: Colors.white)
                      : null,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: const Icon(Icons.edit_rounded, size: 14, color: Color(0xFFE67E22)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName.isNotEmpty ? user.fullName : l10n.guestUser,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85)),
                ),
                if (user.phone != null && user.phone!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    user.phone!,
                    style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuItem {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

class _ProfileMenuGroup extends StatelessWidget {
  final List<_ProfileMenuItem> items;

  const _ProfileMenuGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C3E50).withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _ProfileMenuTile(item: items[i]),
            if (i != items.length - 1)
              const Divider(height: 1, indent: 64, endIndent: 16, color: Color(0xFFF1EAE1)),
          ],
        ],
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  final _ProfileMenuItem item;

  const _ProfileMenuTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, size: 20, color: item.color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF95A5A6),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFBDC3C7),
            ),
          ],
        ),
      ),
    );
  }
}
