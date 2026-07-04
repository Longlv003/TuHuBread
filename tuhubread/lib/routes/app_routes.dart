import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tuhubread/pages/login_page.dart';
import 'package:tuhubread/pages/my_home_page.dart';
import 'package:tuhubread/pages/register_page.dart';
import 'package:tuhubread/pages/splash_page.dart';
import 'package:tuhubread/routes/routes.dart';

class AppRoutes {
  List<GetPage> get routes => <GetPage>[
    _getPage(name: Routes.splashPage, page: () => SplashPage()),
    _getPage(name: Routes.loginPage, page: () => LoginPage()),
    _getPage(name: Routes.registerPage, page: () => RegisterPage()),
    _getPage(name: Routes.homePage, page: () => MyHomePage()),
  ];

  GetPage _getPage({required String name, required Widget Function() page}) =>
      GetPage(name: name, page: page);
}
