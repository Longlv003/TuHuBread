import 'package:flutter/material.dart';
import 'package:get/get.dart' as getx;
import 'package:tuhubread/l10n/app_localizations.dart';

import '../utils/locale_prefs.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Future<void> _changeLocale(Locale locale) async {
    await LocalePrefs.saveLocale(locale);
    getx.Get.updateLocale(locale);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentLanguageCode = getx.Get.locale?.languageCode ?? 'vi';

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.profileSettings,
          style: const TextStyle(color: Color(0xFF2C3E50), fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2C3E50)),
          onPressed: () => getx.Get.back(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.settingsLanguageSection,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1EAE1)),
              ),
              child: Column(
                children: [
                  RadioListTile<String>(
                    value: 'vi',
                    groupValue: currentLanguageCode,
                    activeColor: const Color(0xFFE67E22),
                    title: Text(l10n.settingsLanguageVietnamese),
                    onChanged: (_) => _changeLocale(const Locale('vi')),
                  ),
                  const Divider(height: 1, color: Color(0xFFF1EAE1)),
                  RadioListTile<String>(
                    value: 'en',
                    groupValue: currentLanguageCode,
                    activeColor: const Color(0xFFE67E22),
                    title: Text(l10n.settingsLanguageEnglish),
                    onChanged: (_) => _changeLocale(const Locale('en')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
