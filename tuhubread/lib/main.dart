import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tuhubread/di.dart';
import 'package:tuhubread/firebase_options.dart';
import 'package:tuhubread/services/notification_service.dart';
import 'package:tuhubread/utils/locale_prefs.dart';

import 'app.dart';
import 'flavors.dart';

/// Xử lý FCM lúc app đang chạy nền/tắt hẳn. Bắt buộc là hàm top-level (không
/// phải method trong class) vì Flutter chạy nó ở 1 isolate riêng biệt —
/// isolate đó chưa có Firebase.initializeApp() nên phải gọi lại ở đây.
/// Hệ điều hành tự hiển thị banner thông báo từ field "notification" của
/// payload, không cần code gì thêm để hiện banner trong trường hợp này.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark, // Chữ/Icon tối trên Android
      statusBarBrightness: Brightness.light, // Chữ/Icon tối trên iOS
    ),
  );
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  F.appFlavor = Flavor.values.firstWhere(
    (element) => element.name == appFlavor,
  );
  await init();
  
  // Initialize Notification Service (FCM listeners, etc.)
  try {
    await getIt<NotificationService>().init();
  } catch (e) {
    debugPrint('Failed to initialize NotificationService: $e');
  }

  final savedLocale = await LocalePrefs.getSavedLocale();
  runApp(App(initialLocale: savedLocale));
}
