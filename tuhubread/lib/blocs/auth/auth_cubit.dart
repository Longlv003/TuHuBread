import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/account.model.dart';
import '../../services/api_service.dart';
import 'auth_state.dart';

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
        final account = AccountModel.fromJson(response['data'] as Map<String, dynamic>);
        emit(AuthSuccess(account));
      } else {
        emit(AuthFailure(response['msg'] ?? defaultLoginError));
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        emit(AuthFailure(timeoutErrorMsg));
      } else {
        emit(AuthFailure(networkErrorMsg));
      }
    } catch (e) {
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
        emit(const AuthFailure('Không lấy được token xác thực'));
      }
    } on FirebaseAuthException catch (e) {
      final errorMsg = firebaseErrors[e.code] ??
          firebaseErrors['invalid-credential'] ??
          e.message ??
          firebaseErrors['default'] ??
          defaultLoginError;
      emit(AuthFailure(errorMsg));
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        emit(AuthFailure(timeoutErrorMsg));
      } else {
        emit(AuthFailure(networkErrorMsg));
      }
    } catch (e) {
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
      final token = await userCredential.user?.getIdToken();

      if (token != null) {
        await verifyFirebaseToken(
          token,
          defaultLoginError: defaultRegisterError,
          networkErrorMsg: networkErrorMsg,
          timeoutErrorMsg: timeoutErrorMsg,
        );
      } else {
        emit(const AuthFailure('Không lấy được token xác thực'));
      }
    } on FirebaseAuthException catch (e) {
      final errorMsg = firebaseErrors[e.code] ??
          e.message ??
          firebaseErrors['default'] ??
          defaultRegisterError;
      emit(AuthFailure(errorMsg));
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        emit(AuthFailure(timeoutErrorMsg));
      } else {
        emit(AuthFailure(networkErrorMsg));
      }
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> handleFacebookAuth({
    required String defaultLoginError,
    required String networkErrorMsg,
    required String timeoutErrorMsg,
  }) async {
    emit(const AuthLoading());
    await Future.delayed(const Duration(milliseconds: 800));
    await verifyFirebaseToken(
      'mock_facebook_token',
      defaultLoginError: defaultLoginError,
      networkErrorMsg: networkErrorMsg,
      timeoutErrorMsg: timeoutErrorMsg,
    );
  }

  Future<void> handleGoogleAuth({
    required String defaultLoginError,
    required String networkErrorMsg,
    required String timeoutErrorMsg,
  }) async {
    emit(const AuthLoading());
    await Future.delayed(const Duration(milliseconds: 800));
    await verifyFirebaseToken(
      'mock_google_token',
      defaultLoginError: defaultLoginError,
      networkErrorMsg: networkErrorMsg,
      timeoutErrorMsg: timeoutErrorMsg,
    );
  }

  Future<void> handleLogout() async {
    await FirebaseAuth.instance.signOut();
    emit(const AuthInitial());
  }

  void reset() {
    emit(const AuthInitial());
  }
}
