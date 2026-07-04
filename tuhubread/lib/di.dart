import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:tuhubread/blocs/splash/splash_cubit.dart';

final getIt = GetIt.instance;

Future<void> init() async {
  getIt.registerLazySingleton<Logger>(() => Logger());

  getIt.registerFactory<SplashCubit>(() => SplashCubit());
}
