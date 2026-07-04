import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:tuhubread/blocs/auth/auth_cubit.dart';
import 'package:tuhubread/blocs/splash/splash_cubit.dart';
import 'package:tuhubread/blocs/splash/splash_state.dart';
import 'package:tuhubread/di.dart';
import 'package:tuhubread/l10n/app_localizations.dart';
import 'package:tuhubread/routes/routes.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocProvider(
      create: (_) => getIt<SplashCubit>()..initializeApp(),
      child: BlocListener<SplashCubit, SplashState>(
        listener: (context, state) {
          if (state is SplashLoaded) {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              user.getIdToken().then((token) {
                if (token != null) {
                  // Sync Firebase Token with Node.js backend
                  context.read<AuthCubit>().verifyFirebaseToken(
                        token,
                        defaultLoginError: l10n.loginFailureDefault,
                        networkErrorMsg: l10n.networkError,
                        timeoutErrorMsg: l10n.connectionTimeoutError,
                      );
                  Get.offAllNamed(Routes.homePage);
                } else {
                  Get.offAllNamed(Routes.loginPage);
                }
              }).catchError((_) {
                Get.offAllNamed(Routes.loginPage);
              });
            } else {
              Get.offAllNamed(Routes.loginPage);
            }
          }
        },
        child: BlocBuilder<SplashCubit, SplashState>(
          builder: (context, state) {
            return Scaffold(
              body: Center(
                child: state is SplashLoading
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(l10n.loadingMessage),
                        ],
                      )
                    : state is SplashError
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("${l10n.splashErrorMessage}${state.message}"),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              context.read<SplashCubit>().initializeApp();
                            },
                            child: Text(l10n.retryButton),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(l10n.welcomeMessage),
                        ],
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
}
