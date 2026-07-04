import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:tuhubread/blocs/auth/auth_cubit.dart';
import 'package:tuhubread/blocs/splash/splash_cubit.dart';
import 'package:tuhubread/services/api_service.dart';

final getIt = GetIt.instance;

Future<void> init() async {
  getIt.registerLazySingleton<Logger>(() => Logger());
  getIt.registerLazySingleton<ApiService>(() => ApiService());
  getIt.registerLazySingleton<AuthCubit>(() => AuthCubit(apiService: getIt<ApiService>()));

  getIt.registerFactory<SplashCubit>(() => SplashCubit());
}

