// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get loadingMessage => 'Đang tải';

  @override
  String get welcomeMessage => 'Xin chào';

  @override
  String get loginTitle => 'TuHuBread';

  @override
  String get loginSlogan => 'Bánh mì nóng hổi, giao nhanh tận tay';

  @override
  String get loginHeading => 'Đăng nhập tài khoản';

  @override
  String get loginSubheading => 'Vui lòng điền email và mật khẩu của bạn';

  @override
  String get emailHint => 'Email';

  @override
  String get passwordHint => 'Mật khẩu';

  @override
  String get confirmPasswordHint => 'Xác nhận mật khẩu';

  @override
  String get loginButton => 'Đăng nhập';

  @override
  String get noAccountText => 'Chưa có tài khoản? ';

  @override
  String get registerNowLink => 'Đăng ký ngay';

  @override
  String get orText => 'HOẶC';

  @override
  String get registerTitle => 'Tạo tài khoản mới';

  @override
  String get registerSlogan => 'Bắt đầu thưởng thức bánh mì ngon lành';

  @override
  String get fullNameHint => 'Họ tên';

  @override
  String get registerButtonText => 'Đăng ký ngay';

  @override
  String get hasAccountText => 'Đã có tài khoản? ';

  @override
  String get logoutButton => 'Đăng xuất';

  @override
  String get roleLabel => 'Vai trò: ';

  @override
  String get emptyFieldsError => 'Vui lòng nhập đầy đủ thông tin';

  @override
  String get passwordMismatchError => 'Mật khẩu xác nhận không khớp!';

  @override
  String get emptyEmailPassError => 'Vui lòng nhập đầy đủ email và mật khẩu';

  @override
  String get invalidEmailError => 'Email không đúng định dạng';

  @override
  String get splashErrorMessage => 'Đã xảy ra lỗi: ';

  @override
  String get retryButton => 'Thử lại';

  @override
  String get firebaseErrorInvalidCredential =>
      'Email hoặc mật khẩu không chính xác';

  @override
  String get firebaseErrorUserDisabled => 'Tài khoản này đã bị vô hiệu hóa';

  @override
  String get firebaseErrorTooManyRequests =>
      'Quá nhiều yêu cầu thất bại. Vui lòng thử lại sau';

  @override
  String get firebaseErrorEmailAlreadyInUse => 'Email này đã được sử dụng';

  @override
  String get firebaseErrorWeakPassword => 'Mật khẩu quá yếu';

  @override
  String get firebaseErrorDefault => 'Xác thực thất bại';

  @override
  String get networkError =>
      'Lỗi kết nối mạng, vui lòng kiểm tra lại đường truyền';

  @override
  String get connectionTimeoutError => 'Kết nối quá hạn, vui lòng thử lại sau';

  @override
  String get registerFailureDefault => 'Đăng ký tài khoản thất bại';

  @override
  String get loginFailureDefault => 'Đăng nhập tài khoản thất bại';
}
