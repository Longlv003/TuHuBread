import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

/// Cầu nối để các lớp KHÔNG có `BuildContext` — repository, cubit, service —
/// lấy được chuỗi đã dịch.
///
/// `AppLocalizations.of(context)` chỉ dùng được trong cây widget, nên trước đây
/// toàn bộ thông báo lỗi ở tầng repository/cubit bị viết cứng tiếng Việt: đổi
/// app sang tiếng Anh thì mọi thông báo lỗi vẫn hiện tiếng Việt.
///
/// [setLocale] phải được gọi mỗi khi ngôn ngữ đổi (lúc khởi động app và trong
/// màn hình Cài đặt) để giữ đồng bộ với locale mà GetMaterialApp đang dùng.
class AppStrings {
  AppStrings._();

  static AppLocalizations _current = lookupAppLocalizations(const Locale('vi'));

  /// Bộ chuỗi của ngôn ngữ đang chọn.
  static AppLocalizations get current => _current;

  static void setLocale(Locale locale) {
    _current = lookupAppLocalizations(locale);
  }
}
