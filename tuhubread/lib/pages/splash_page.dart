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

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _logoScale = CurvedAnimation(parent: _controller, curve: const Interval(0, 0.7, curve: Curves.elasticOut));
    _fade = CurvedAnimation(parent: _controller, curve: const Interval(0.3, 1, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
        child: Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFF6EC), Color(0xFFFDFBF7)],
              ),
            ),
            child: SafeArea(
              child: BlocBuilder<SplashCubit, SplashState>(
                builder: (context, state) {
                  if (state is SplashError) {
                    return _ErrorContent(message: state.message);
                  }
                  return _LoadingContent(logoScale: _logoScale, fade: _fade, l10n: l10n);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingContent extends StatelessWidget {
  final Animation<double> logoScale;
  final Animation<double> fade;
  final AppLocalizations l10n;

  const _LoadingContent({required this.logoScale, required this.fade, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(flex: 3),
        ScaleTransition(
          scale: logoScale,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFF39C12).withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE67E22), width: 3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD35400).withOpacity(0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.bakery_dining_rounded,
                size: 68,
                color: Color(0xFFD35400),
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        FadeTransition(
          opacity: fade,
          child: Column(
            children: [
              Text(
                l10n.loginTitle,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2C3E50),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.loginSlogan,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF7F8C8D),
                ),
              ),
            ],
          ),
        ),
        const Spacer(flex: 2),
        FadeTransition(
          opacity: fade,
          child: const _PulsingDots(),
        ),
        const SizedBox(height: 48),
      ],
    );
  }
}

/// 3 chấm nhảy tuần tự thay cho spinner mặc định — cảm giác hiện đại hơn.
class _PulsingDots extends StatefulWidget {
  const _PulsingDots();

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = (_controller.value - i * 0.2) % 1.0;
            final scale = 0.6 + 0.4 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE67E22),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _ErrorContent extends StatelessWidget {
  final String message;

  const _ErrorContent({required this.message});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFFFDECEA),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded, size: 44, color: Color(0xFFE74C3C)),
            ),
            const SizedBox(height: 24),
            Text(
              "${l10n.splashErrorMessage}$message",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF7F8C8D)),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.read<SplashCubit>().initializeApp();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE67E22),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text(l10n.retryButton, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
