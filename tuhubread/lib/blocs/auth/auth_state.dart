import '../../models/account.model.dart';

abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}


class AuthSuccess extends AuthState {
  final AccountModel user;
  const AuthSuccess(this.user);
}

class AuthFailure extends AuthState {
  final String error;
  const AuthFailure(this.error);
}
