import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';
import '../../models/user.model.dart';
import '../../services/api_service.dart';
import 'auth_state.dart';
import '../../di.dart';
import '../cart/cart_cubit.dart';

final _log = Logger(
  printer: PrettyPrinter(methodCount: 2, colors: true, printEmojis: true),
);

class AuthCubit extends Cubit<AuthState> {
  final ApiService apiService;

  AuthCubit({required this.apiService}) : super(const AuthInitial());

  Future<void> verifyFirebaseToken(
    String firebaseToken, {
    required String defaultLoginError,
    required String networkErrorMsg,
    required String timeoutErrorMsg,
  }) async {
    emit(const AuthLoading());
    try {
      apiService.updateToken(firebaseToken);
      final response = await apiService.post('/api/auth/firebase', {});
      if (response['data'] != null) {
        final user = UserModel.fromJson(response['data'] as Map<String, dynamic>);
        emit(AuthSuccess(user));
        try {
          getIt<CartCubit>().loadCart();
        } catch (_) {}
      } else {
        emit(AuthFailure(response['msg'] ?? defaultLoginError));
      }
    } on DioException catch (e) {
      _log.e('[verifyFirebaseToken] DioException', error: e, stackTrace: e.stackTrace);
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        emit(AuthFailure(timeoutErrorMsg));
      } else {
        emit(AuthFailure(networkErrorMsg));
      }
    } catch (e, s) {
      _log.e('[verifyFirebaseToken] Unexpected error', error: e, stackTrace: s);
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> loginWithEmailAndPassword(
    String email,
    String password, {
    required String emptyFieldsError,
    required String invalidEmailError,
    required Map<String, String> firebaseErrors,
    required String defaultLoginError,
    required String networkErrorMsg,
    required String timeoutErrorMsg,
  }) async {
    if (email.isEmpty || password.isEmpty) {
      emit(AuthFailure(emptyFieldsError));
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      emit(AuthFailure(invalidEmailError));
      return;
    }

    emit(const AuthLoading());
    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final token = await userCredential.user?.getIdToken();

      if (token != null) {
        await verifyFirebaseToken(
          token,
          defaultLoginError: defaultLoginError,
          networkErrorMsg: networkErrorMsg,
          timeoutErrorMsg: timeoutErrorMsg,
        );
      } else {
        emit(AuthFailure(defaultLoginError));
      }
    } on FirebaseAuthException catch (e) {
      _log.w('[loginWithEmailAndPassword] FirebaseAuthException code=${e.code}', error: e);
      final errorMsg = firebaseErrors[e.code] ??
          firebaseErrors['invalid-credential'] ??
          e.message ??
          firebaseErrors['default'] ??
          defaultLoginError;
      emit(AuthFailure(errorMsg));
    } on DioException catch (e) {
      _log.e('[loginWithEmailAndPassword] DioException', error: e, stackTrace: e.stackTrace);
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        emit(AuthFailure(timeoutErrorMsg));
      } else {
        emit(AuthFailure(networkErrorMsg));
      }
    } catch (e, s) {
      _log.e('[loginWithEmailAndPassword] Unexpected error', error: e, stackTrace: s);
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> registerWithEmailAndPassword(
    String name,
    String email,
    String password,
    String confirmPassword, {
    required String emptyFieldsError,
    required String passwordMismatchError,
    required String invalidEmailError,
    required Map<String, String> firebaseErrors,
    required String defaultRegisterError,
    required String networkErrorMsg,
    required String timeoutErrorMsg,
  }) async {
    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      emit(AuthFailure(emptyFieldsError));
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      emit(AuthFailure(invalidEmailError));
      return;
    }

    if (password != confirmPassword) {
      emit(AuthFailure(passwordMismatchError));
      return;
    }

    emit(const AuthLoading());
    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user?.updateDisplayName(name);
      // Force refresh để token mới chứa displayName đã cập nhật
      final token = await userCredential.user?.getIdToken(true);

      if (token != null) {
        await verifyFirebaseToken(
          token,
          defaultLoginError: defaultRegisterError,
          networkErrorMsg: networkErrorMsg,
          timeoutErrorMsg: timeoutErrorMsg,
        );
      } else {
        emit(AuthFailure(defaultRegisterError));
      }
    } on FirebaseAuthException catch (e) {
      _log.w('[registerWithEmailAndPassword] FirebaseAuthException code=${e.code}', error: e);
      final errorMsg = firebaseErrors[e.code] ??
          e.message ??
          firebaseErrors['default'] ??
          defaultRegisterError;
      emit(AuthFailure(errorMsg));
    } on DioException catch (e) {
      _log.e('[registerWithEmailAndPassword] DioException', error: e, stackTrace: e.stackTrace);
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        emit(AuthFailure(timeoutErrorMsg));
      } else {
        emit(AuthFailure(networkErrorMsg));
      }
    } catch (e, s) {
      _log.e('[registerWithEmailAndPassword] Unexpected error', error: e, stackTrace: s);
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> handleFacebookAuth({
    required String defaultLoginError,
    required String networkErrorMsg,
    required String timeoutErrorMsg,
    required String cancelledError,
    required Map<String, String> firebaseErrors,
  }) async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.cancelled) {
        // Người dùng tự huỷ - không emit lỗi, giữ nguyên state
        return;
      }

      if (result.status != LoginStatus.success) {
        emit(AuthFailure(defaultLoginError));
        return;
      }

      emit(const AuthLoading());

      final accessToken = result.accessToken?.tokenString;
      if (accessToken == null) {
        emit(AuthFailure(defaultLoginError));
        return;
      }

      // Đổi Facebook access token lấy Firebase credential
      final credential = FacebookAuthProvider.credential(accessToken);
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final token = await userCredential.user?.getIdToken();

      if (token != null) {
        await verifyFirebaseToken(
          token,
          defaultLoginError: defaultLoginError,
          networkErrorMsg: networkErrorMsg,
          timeoutErrorMsg: timeoutErrorMsg,
        );
      } else {
        emit(AuthFailure(defaultLoginError));
      }
    } on FirebaseAuthException catch (e) {
      _log.w('[handleFacebookAuth] FirebaseAuthException code=${e.code}', error: e);
      final errorMsg = firebaseErrors[e.code] ?? e.message ?? defaultLoginError;
      emit(AuthFailure(errorMsg));
    } on DioException catch (e) {
      _log.e('[handleFacebookAuth] DioException', error: e, stackTrace: e.stackTrace);
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        emit(AuthFailure(timeoutErrorMsg));
      } else {
        emit(AuthFailure(networkErrorMsg));
      }
    } catch (e, s) {
      _log.e('[handleFacebookAuth] Unexpected error', error: e, stackTrace: s);
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> handleGoogleAuth({
    required String defaultLoginError,
    required String networkErrorMsg,
    required String timeoutErrorMsg,
    required String cancelledError,
    required Map<String, String> firebaseErrors,
  }) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // Người dùng tự huỷ - không emit lỗi, giữ nguyên state
        return;
      }

      emit(const AuthLoading());

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final token = await userCredential.user?.getIdToken();

      if (token != null) {
        await verifyFirebaseToken(
          token,
          defaultLoginError: defaultLoginError,
          networkErrorMsg: networkErrorMsg,
          timeoutErrorMsg: timeoutErrorMsg,
        );
      } else {
        emit(AuthFailure(defaultLoginError));
      }
    } on FirebaseAuthException catch (e) {
      _log.w('[handleGoogleAuth] FirebaseAuthException code=${e.code}', error: e);
      final errorMsg = firebaseErrors[e.code] ?? e.message ?? defaultLoginError;
      emit(AuthFailure(errorMsg));
    } on DioException catch (e) {
      _log.e('[handleGoogleAuth] DioException', error: e, stackTrace: e.stackTrace);
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        emit(AuthFailure(timeoutErrorMsg));
      } else {
        emit(AuthFailure(networkErrorMsg));
      }
    } catch (e, s) {
      _log.e('[handleGoogleAuth] Unexpected error', error: e, stackTrace: s);
      emit(AuthFailure(e.toString()));
    }
  }

  /// Cập nhật tên/số điện thoại. Trả về null nếu thành công, ngược lại trả
  /// về thông báo lỗi. Không emit AuthLoading/AuthFailure để tránh làm
  /// MyHomePage (đang lắng nghe AuthCubit toàn app) rơi về màn loading.
  Future<String?> updateProfile({
    String? fullName,
    String? phone,
    required String defaultErrorMsg,
  }) async {
    final currentState = state;
    if (currentState is! AuthSuccess) return defaultErrorMsg;

    try {
      final response = await apiService.put('/api/account/profile', {
        if (fullName != null) 'full_name': fullName,
        if (phone != null) 'phone': phone,
      });

      if (response['data'] != null) {
        final user = UserModel.fromJson(response['data'] as Map<String, dynamic>);
        emit(AuthSuccess(user));
        return null;
      }
      return response['msg'] ?? defaultErrorMsg;
    } catch (e, s) {
      _log.e('[updateProfile] Unexpected error', error: e, stackTrace: s);
      return defaultErrorMsg;
    }
  }

  /// Tải ảnh đại diện mới. Trả về null nếu thành công, ngược lại trả về
  /// thông báo lỗi.
  Future<String?> uploadAvatar(File file, {required String defaultErrorMsg}) async {
    final currentState = state;
    if (currentState is! AuthSuccess) return defaultErrorMsg;

    try {
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(file.path),
      });
      final response = await apiService.post('/api/account/avatar', formData);

      if (response['data'] != null) {
        final user = UserModel.fromJson(response['data'] as Map<String, dynamic>);
        emit(AuthSuccess(user));
        return null;
      }
      return response['msg'] ?? defaultErrorMsg;
    } catch (e, s) {
      _log.e('[uploadAvatar] Unexpected error', error: e, stackTrace: s);
      return defaultErrorMsg;
    }
  }

  Future<void> handleLogout() async {
    // Logout khỏi Firebase
    await FirebaseAuth.instance.signOut();

    // Logout khỏi Google (nếu có - bỏ qua nếu chưa khởi tạo)
    try {
      await GoogleSignIn().signOut();
    } catch (e) {
      _log.w('[handleLogout] Google signOut skipped', error: e);
    }

    // Logout khỏi Facebook (nếu có)
    try {
      await FacebookAuth.instance.logOut();
    } catch (e) {
      _log.w('[handleLogout] Facebook logOut skipped', error: e);
    }

    try {
      getIt<CartCubit>().clearCart();
    } catch (_) {}

    emit(const AuthInitial());
  }

  void reset() {
    emit(const AuthInitial());
  }
}
