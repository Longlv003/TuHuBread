import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tuhubread/blocs/splash/splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  SplashCubit() : super(SplashInitial());

  Future<void> initializeApp() async {
    try {
      emit(SplashLoading());
      await Future.delayed(Duration(seconds: 5));
      emit(SplashLoaded());
    } catch (e) {
      emit(SplashError(e.toString()));
    }
  }
}
