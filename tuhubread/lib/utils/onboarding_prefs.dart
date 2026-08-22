import 'package:shared_preferences/shared_preferences.dart';

/// Ghi nhớ khách đã xem màn giới thiệu (onboarding) hay chưa, để chỉ hiện
/// đúng một lần ở lần mở app đầu tiên.
class OnboardingPrefs {
  static const _key = 'onboarding_seen';

  static Future<bool> hasSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  static Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}
