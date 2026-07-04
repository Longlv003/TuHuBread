import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
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
            Get.offAllNamed(Routes.homePage);
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
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(l10n.loadingMessage),
                        ],
                      )
                    : state is SplashError
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Error: ${state.message}"),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              context.read<SplashCubit>().initializeApp();
                            },
                            child: Text("Retry"),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
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
