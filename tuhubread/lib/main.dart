import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tuhubread/firebase_options.dart';
import 'package:tuhubread/di.dart';
import 'package:tuhubread/utils/locale_prefs.dart';

import 'app.dart';
import 'flavors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  F.appFlavor = Flavor.values.firstWhere(
    (element) => element.name == appFlavor,
  );
  await init();
  final savedLocale = await LocalePrefs.getSavedLocale();
  runApp(App(initialLocale: savedLocale));
}
