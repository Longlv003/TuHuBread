import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart' as getx;
import 'package:tuhubread/l10n/app_localizations.dart';

import '../blocs/auth/auth_cubit.dart';
import '../blocs/auth/auth_state.dart';
import '../models/user.model.dart';
import '../routes/routes.dart';
import '../widgets/customer_bottom_nav.dart';
import '../widgets/customer_header.dart';
import 'tabs/cart_tab.dart';
import 'tabs/history_tab.dart';
import 'tabs/home_tab.dart';
import 'tabs/profile_tab.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;
  int _unreadNotifications = 3; // Demo notification count

  void _onBellPressed() {
    if (_unreadNotifications > 0) {
      setState(() {
        _unreadNotifications--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthInitial) {
          getx.Get.offAllNamed(Routes.loginPage);
        }
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is AuthSuccess) {
            final user = state.user;

            // List of views for each tab
            final List<Widget> tabViews = [
              HomeTab(user: user),
              CartTab(user: user),
              HistoryTab(user: user),
              ProfileTab(user: user),
            ];

            return Scaffold(
              backgroundColor: const Color(0xFFFDFBF7),
              body: SafeArea(
                child: Column(
                  children: [
                    // Extracted Reusable Header Customer
                    CustomerHeader(
                      user: user,
                      titleWidget: _buildHeaderWidgetForTab(user, l10n),
                      unreadNotifications: _unreadNotifications,
                      onNotificationTap: _onBellPressed,
                    ),
                    const Divider(height: 1, color: Color(0xFFF1EAE1)),
                    // Active Tab View Content
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: tabViews[_currentIndex],
                      ),
                    ),
                  ],
                ),
              ),
              // Extracted Reusable Bottom Navigation Bar
              bottomNavigationBar: CustomerBottomNav(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              ),
            );
          }
          return Scaffold(
            body: Center(child: Text(l10n.loadingMessage)),
          );
        },
      ),
    );
  }

  // Header Custom Widget depending on current tab
  Widget _buildHeaderWidgetForTab(UserModel user, AppLocalizations l10n) {
    switch (_currentIndex) {
      case 0: // Home Tab Header: User Welcome Info
        final avatar = user.avatarUrl;
        final hasAvatar = avatar != null && avatar.isNotEmpty;
        return Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFE67E22).withOpacity(0.2),
              backgroundImage: hasAvatar ? NetworkImage(avatar) : null,
              child: !hasAvatar
                  ? const Icon(
                      Icons.person_rounded,
                      size: 20,
                      color: Color(0xFFD35400),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n.welcomeMessage},',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF7F8C8D)),
                  ),
                  Text(
                    user.fullName.isNotEmpty ? user.fullName : l10n.guestUser,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        );
      case 1:
        return Text(
          l10n.cartTitle,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
        );
      case 2:
        return Text(
          l10n.historyTitle,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
        );
      case 3:
        return Text(
          l10n.profileTitle,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
