import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart' as getx;
import 'package:tuhubread/l10n/app_localizations.dart';

import '../blocs/auth/auth_cubit.dart';
import '../blocs/auth/auth_state.dart';
import '../flavors.dart';
import '../routes/routes.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthInitial) {
          getx.Get.offAllNamed(Routes.loginPage);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFCF9F6),
        appBar: AppBar(
          title: Text(F.title),
          backgroundColor: const Color(0xFFE67E22),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.white),
              onPressed: () {
                context.read<AuthCubit>().handleLogout();
              },
            ),
          ],
        ),
        body: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            if (state is AuthSuccess) {
              final user = state.user;
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Builder(
                        builder: (context) {
                          final avatar = user.avatarUrl;
                          final hasAvatar = avatar != null && avatar.isNotEmpty;
                          return CircleAvatar(
                            radius: 50,
                            backgroundColor: const Color(0xFFE67E22).withOpacity(0.2),
                            backgroundImage: hasAvatar ? NetworkImage(avatar) : null,
                            child: !hasAvatar
                                ? const Icon(
                                    Icons.person_rounded,
                                    size: 50,
                                    color: Color(0xFFD35400),
                                  )
                                : null,
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      Text(
                        user.fullName.isNotEmpty ? user.fullName : 'Khách TuHu',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${l10n.roleLabel}${user.role}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF95A5A6),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton.icon(
                        onPressed: () {
                          context.read<AuthCubit>().handleLogout();
                        },
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: Colors.white,
                        ),
                        label: Text(
                          l10n.logoutButton,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC0392B),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Center(child: Text(l10n.loadingMessage));
          },
        ),
      ),
    );
  }
}
