import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:tuhubread/blocs/auth/auth_cubit.dart';
import 'package:tuhubread/configs/system.dart';
import 'package:tuhubread/di.dart';
import 'package:tuhubread/l10n/app_localizations.dart';
import 'package:tuhubread/routes/app_routes.dart';
import 'package:tuhubread/routes/routes.dart';

import 'flavors.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<AuthCubit>(
        create: (context) => getIt<AuthCubit>(),
        child: GetMaterialApp(
          title: F.title,
          debugShowCheckedModeBanner: false,
          builder: (context, child) => Material(child: child),
          navigatorKey: System.navigatorKey,
          getPages: AppRoutes().routes,
          initialRoute: Routes.splashPage,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      );
}
