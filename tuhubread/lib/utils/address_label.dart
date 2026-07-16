import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Nhãn phân loại địa chỉ (Nhà/Công ty/Khác) — icon + text hiển thị dùng
/// chung giữa [AddressFormPage] và [SelectAddressPage].
IconData addressLabelIcon(String label) {
  switch (label) {
    case 'home':
      return Icons.home_rounded;
    case 'company':
      return Icons.business_rounded;
    default:
      return Icons.bookmark_rounded;
  }
}

String addressLabelText(AppLocalizations l10n, String label) {
  switch (label) {
    case 'home':
      return l10n.addressLabelHome;
    case 'company':
      return l10n.addressLabelCompany;
    default:
      return l10n.addressLabelOther;
  }
}
