import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tuhubread/blocs/splash/splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  SplashCubit() : super(SplashInitial());

  Future<void> initializeApp() async {
    try {
      emit(SplashLoading());
      // Đợi Firebase Auth khôi phục xong phiên đăng nhập cũ (nếu có) từ bộ
      // nhớ máy trước khi splash_page.dart đọc FirebaseAuth.instance.currentUser
      // — currentUser có thể vẫn null ngay sau Firebase.initializeApp() vì SDK
      // Auth khôi phục phiên bất đồng bộ, không đồng bộ với lúc app khởi động.
      // Giới hạn 5s để không treo màn hình splash mãi nếu stream không bao giờ bắn.
      await FirebaseAuth.instance.authStateChanges().first.timeout(
            const Duration(seconds: 5),
            onTimeout: () => FirebaseAuth.instance.currentUser,
          );
      emit(SplashLoaded());
    } catch (e) {
      emit(SplashError(e.toString()));
    }
  }
}
