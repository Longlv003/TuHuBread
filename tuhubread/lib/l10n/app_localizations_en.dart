// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get loadingMessage => 'Loading';

  @override
  String get welcomeMessage => 'Welcome';

  @override
  String get loginTitle => 'TuHuBread';

  @override
  String get loginSlogan => 'Hot bread, fast delivery';

  @override
  String get loginHeading => 'Login Account';

  @override
  String get loginSubheading => 'Please enter your email and password';

  @override
  String get emailHint => 'Email';

  @override
  String get passwordHint => 'Password';

  @override
  String get confirmPasswordHint => 'Confirm Password';

  @override
  String get loginButton => 'Login';

  @override
  String get noAccountText => 'Don\'t have an account? ';

  @override
  String get registerNowLink => 'Register Now';

  @override
  String get orText => 'OR';

  @override
  String get registerTitle => 'Create New Account';

  @override
  String get registerSlogan => 'Start enjoying delicious bread';

  @override
  String get fullNameHint => 'Full Name';

  @override
  String get registerButtonText => 'Register Now';

  @override
  String get hasAccountText => 'Already have an account? ';

  @override
  String get logoutButton => 'Sign Out';

  @override
  String get roleLabel => 'Role: ';

  @override
  String get emptyFieldsError => 'Please fill in all fields';

  @override
  String get passwordMismatchError => 'Passwords do not match!';

  @override
  String get emptyEmailPassError => 'Please enter both email and password';

  @override
  String get invalidEmailError => 'Invalid email format';

  @override
  String get splashErrorMessage => 'Error: ';

  @override
  String get retryButton => 'Retry';

  @override
  String get firebaseErrorInvalidCredential => 'Incorrect email or password';

  @override
  String get firebaseErrorUserDisabled => 'This account has been disabled';

  @override
  String get firebaseErrorTooManyRequests =>
      'Too many failed attempts. Please try again later';

  @override
  String get firebaseErrorEmailAlreadyInUse => 'This email is already in use';

  @override
  String get firebaseErrorWeakPassword => 'Password is too weak';

  @override
  String get firebaseErrorDefault => 'Authentication failed';

  @override
  String get networkError => 'Network error, please check your connection';

  @override
  String get connectionTimeoutError => 'Connection timeout, please try again';

  @override
  String get registerFailureDefault => 'Registration failed';

  @override
  String get loginFailureDefault => 'Login failed';

  @override
  String get loginCancelledError => 'Login was cancelled';

  @override
  String get firebaseErrorAccountExistsWithDifferentCredential =>
      'An account already exists with this email using a different sign-in method';
}
