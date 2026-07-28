import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:tuhubread/blocs/auth/auth_cubit.dart';
import 'package:tuhubread/blocs/cart/cart_cubit.dart';
import 'package:tuhubread/configs/system.dart';
import 'package:tuhubread/di.dart';
import 'package:tuhubread/l10n/app_localizations.dart';
import 'package:tuhubread/routes/app_routes.dart';
import 'package:tuhubread/routes/routes.dart';

import 'flavors.dart';

class App extends StatelessWidget {
  final Locale? initialLocale;

  const App({super.key, this.initialLocale});

  @override
  Widget build(BuildContext context) => GetMaterialApp(
        title: F.title,
        debugShowCheckedModeBanner: false,
        builder: (context, child) => MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>.value(value: getIt<AuthCubit>()),
            BlocProvider<CartCubit>.value(value: getIt<CartCubit>()),
          ],
          child: Material(child: child),
        ),
        navigatorKey: System.navigatorKey,
        getPages: AppRoutes().routes,
        initialRoute: Routes.splashPage,
        locale: initialLocale ?? const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      );
}
