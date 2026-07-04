import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tuhubread/configs/system.dart';
import 'package:tuhubread/routes/app_routes.dart';
import 'package:tuhubread/routes/routes.dart';

import 'flavors.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => GetMaterialApp(
    title: F.title,
    debugShowCheckedModeBanner: false,
    builder: (context, child) => Material(child: child),
    navigatorKey: System.navigatorKey,
    // navigatorObservers: [ChuckerFlutter.navigatorObserver],
    getPages: AppRoutes().routes,
    initialRoute: Routes.splashPage,
  );
}
