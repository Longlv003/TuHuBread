import 'package:flutter/material.dart';
import 'package:get/get.dart' as getx;
import 'package:tuhubread/l10n/app_localizations.dart';

import '../core/app_tokens.dart';
import '../routes/routes.dart';
import '../utils/onboarding_prefs.dart';

class _OnboardingSlide {
  final String title;
  final String description;
  final IconData icon;

  /// Màu nền khối minh hoạ — mỗi trang một sắc để lướt qua thấy rõ đã đổi
  /// trang chứ không chỉ đổi chữ.
  final Color accent;

  const _OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
  });
}

/// Màn giới thiệu hiển thị đúng MỘT lần ở lần mở app đầu tiên.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageController = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<_OnboardingSlide> _slides(AppLocalizations l10n) => [
        _OnboardingSlide(
          title: l10n.onboardingTitle1,
          description: l10n.onboardingDesc1,
          icon: Icons.bakery_dining_rounded,
          accent: const Color(0xFFFDF0E5),
        ),
        _OnboardingSlide(
          title: l10n.onboardingTitle2,
          description: l10n.onboardingDesc2,
          icon: Icons.storefront_rounded,
          accent: const Color(0xFFFFF4DC),
        ),
        _OnboardingSlide(
          title: l10n.onboardingTitle3,
          description: l10n.onboardingDesc3,
          icon: Icons.delivery_dining_rounded,
          accent: const Color(0xFFFDECE3),
        ),
      ];

  Future<void> _finish() async {
    await OnboardingPrefs.markSeen();
    getx.Get.offAllNamed(Routes.loginPage);
  }

  void _next(int total) {
    if (_index >= total - 1) {
      _finish();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final slides = _slides(l10n);
    final isLast = _index == slides.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _buildSlide(slides[i]),
              ),
            ),
            _buildDots(slides.length),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _next(slides.length),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    (isLast ? l10n.onboardingStart : l10n.onboardingNext)
                        .toUpperCase(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
            ),
            // Ở trang cuối không còn gì để bỏ qua nữa — vẫn chừa đúng chỗ để
            // nút chính không bị nhảy vị trí khi lướt tới trang cuối.
            SizedBox(
              height: 46,
              child: isLast
                  ? null
                  : Center(
                      child: TextButton(
                        onPressed: _finish,
                        child: Text(
                          l10n.onboardingSkip,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(_OnboardingSlide slide) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              color: slide.accent,
              shape: BoxShape.circle,
            ),
            child: Icon(slide.icon, size: 96, color: AppColors.primaryDark),
          ),
          const SizedBox(height: 44),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textMuted,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDots(int total) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final active = i == _index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : const Color(0xFFF2D9C2),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
