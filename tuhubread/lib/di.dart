import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:tuhubread/blocs/address/address_cubit.dart';
import 'package:tuhubread/blocs/cart/cart_cubit.dart';
import 'package:tuhubread/blocs/auth/auth_cubit.dart';
import 'package:tuhubread/blocs/home/home_cubit.dart';
import 'package:tuhubread/blocs/product_detail/product_detail_cubit.dart';
import 'package:tuhubread/blocs/order/order_cubit.dart';
import 'package:tuhubread/blocs/splash/splash_cubit.dart';
import 'package:tuhubread/blocs/voucher/voucher_cubit.dart';
import 'package:tuhubread/repositories/address_repository.dart';
import 'package:tuhubread/repositories/address_repository_impl.dart';
import 'package:tuhubread/repositories/home_repository.dart';
import 'package:tuhubread/repositories/home_repository_impl.dart';
import 'package:tuhubread/repositories/order_repository.dart';
import 'package:tuhubread/repositories/order_repository_impl.dart';
import 'package:tuhubread/repositories/voucher_repository.dart';
import 'package:tuhubread/repositories/voucher_repository_impl.dart';
import 'package:tuhubread/services/api_service.dart';
import 'package:tuhubread/services/location_service.dart';
import 'package:tuhubread/services/vietnam_address_service.dart';

final getIt = GetIt.instance;

Future<void> init() async {
  // ─── Core services ───────────────────────────────────────────────────────
  getIt.registerLazySingleton<Logger>(() => Logger());
  getIt.registerLazySingleton<ApiService>(() => ApiService());

  // ─── Auth ─────────────────────────────────────────────────────────────────
  getIt.registerLazySingleton<AuthCubit>(
    () => AuthCubit(apiService: getIt<ApiService>()),
  );
  getIt.registerFactory<SplashCubit>(() => SplashCubit());

  // ─── Home ─────────────────────────────────────────────────────────────────
  // Repository: LazySingleton — tái sử dụng, stateless
  getIt.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(apiService: getIt<ApiService>()),
  );
  // Cubit: Factory — tạo mới mỗi lần vào màn Home
  getIt.registerFactory<HomeCubit>(
    () => HomeCubit(repository: getIt<HomeRepository>()),
  );

  // ─── Product Detail ───────────────────────────────────────────────────────
  getIt.registerFactory<ProductDetailCubit>(
    () => ProductDetailCubit(repository: getIt<HomeRepository>()),
  );

  // ─── Cart ─────────────────────────────────────────────────────────────────
  getIt.registerLazySingleton<CartCubit>(() => CartCubit());

  // ─── Voucher ──────────────────────────────────────────────────────────────
  getIt.registerLazySingleton<VoucherRepository>(
    () => VoucherRepositoryImpl(apiService: getIt<ApiService>()),
  );
  getIt.registerFactory<VoucherCubit>(
    () => VoucherCubit(repository: getIt<VoucherRepository>()),
  );

  // ─── Address ──────────────────────────────────────────────────────────────
  getIt.registerLazySingleton<AddressRepository>(
    () => AddressRepositoryImpl(apiService: getIt<ApiService>()),
  );
  getIt.registerFactory<AddressCubit>(
    () => AddressCubit(repository: getIt<AddressRepository>()),
  );
  getIt.registerLazySingleton<VietnamAddressService>(
    () => VietnamAddressService(),
  );
  getIt.registerLazySingleton<LocationService>(() => LocationService());

  // ─── Order ────────────────────────────────────────────────────────────────
  getIt.registerLazySingleton<OrderRepository>(
    () => OrderRepositoryImpl(apiService: getIt<ApiService>()),
  );
  getIt.registerFactory<OrderCubit>(
    () => OrderCubit(apiService: getIt<ApiService>()),
  );
}
