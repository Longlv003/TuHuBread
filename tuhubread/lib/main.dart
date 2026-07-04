import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tuhubread/di.dart';

import 'app.dart';
import 'flavors.dart';

Future<void> main() async {
  F.appFlavor = Flavor.values.firstWhere(
    (element) => element.name == appFlavor,
  );
  await init();
  runApp(const App());
}
