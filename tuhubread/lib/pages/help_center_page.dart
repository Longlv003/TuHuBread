import 'package:flutter/material.dart';
import 'package:get/get.dart' as getx;
import 'package:tuhubread/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  static const String _supportPhone = '19001234';
  static const String _supportEmail = 'support@tuhubread.com';

  Future<void> _launch(Uri uri) async {
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final faqs = [
      (l10n.helpCenterFaq1Question, l10n.helpCenterFaq1Answer),
      (l10n.helpCenterFaq2Question, l10n.helpCenterFaq2Answer),
      (l10n.helpCenterFaq3Question, l10n.helpCenterFaq3Answer),
      (l10n.helpCenterFaq4Question, l10n.helpCenterFaq4Answer),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.profileHelpCenter,
          style: const TextStyle(color: Color(0xFF2C3E50), fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2C3E50)),
          onPressed: () => getx.Get.back(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Text(
            l10n.helpCenterFaqSection,
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
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: Column(
                children: [
                  for (var i = 0; i < faqs.length; i++) ...[
                    ExpansionTile(
                      title: Text(
                        faqs[i].$1,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      iconColor: const Color(0xFFE67E22),
                      collapsedIconColor: const Color(0xFF7F8C8D),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              faqs[i].$2,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF7F8C8D), height: 1.4),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (i != faqs.length - 1)
                      const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF1EAE1)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.helpCenterContactSection,
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
                ListTile(
                  leading: const Icon(Icons.phone_outlined, color: Color(0xFFE67E22)),
                  title: Text(l10n.helpCenterCallSupport),
                  subtitle: const Text(_supportPhone),
                  onTap: () => _launch(Uri(scheme: 'tel', path: _supportPhone)),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF1EAE1)),
                ListTile(
                  leading: const Icon(Icons.email_outlined, color: Color(0xFFE67E22)),
                  title: Text(l10n.helpCenterEmailSupport),
                  subtitle: const Text(_supportEmail),
                  onTap: () => _launch(Uri(scheme: 'mailto', path: _supportEmail)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
