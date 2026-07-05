import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// No description provided for @loadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loadingMessage;

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcomeMessage;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'TuHuBread'**
  String get loginTitle;

  /// No description provided for @loginSlogan.
  ///
  /// In en, this message translates to:
  /// **'Hot bread, fast delivery'**
  String get loginSlogan;

  /// No description provided for @loginHeading.
  ///
  /// In en, this message translates to:
  /// **'Login Account'**
  String get loginHeading;

  /// No description provided for @loginSubheading.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email and password'**
  String get loginSubheading;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailHint;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordHint;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordHint;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @noAccountText.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get noAccountText;

  /// No description provided for @registerNowLink.
  ///
  /// In en, this message translates to:
  /// **'Register Now'**
  String get registerNowLink;

  /// No description provided for @orText.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get orText;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create New Account'**
  String get registerTitle;

  /// No description provided for @registerSlogan.
  ///
  /// In en, this message translates to:
  /// **'Start enjoying delicious bread'**
  String get registerSlogan;

  /// No description provided for @fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullNameHint;

  /// No description provided for @registerButtonText.
  ///
  /// In en, this message translates to:
  /// **'Register Now'**
  String get registerButtonText;

  /// No description provided for @hasAccountText.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get hasAccountText;

  /// No description provided for @logoutButton.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get logoutButton;

  /// No description provided for @roleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role: '**
  String get roleLabel;

  /// No description provided for @emptyFieldsError.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields'**
  String get emptyFieldsError;

  /// No description provided for @passwordMismatchError.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match!'**
  String get passwordMismatchError;

  /// No description provided for @emptyEmailPassError.
  ///
  /// In en, this message translates to:
  /// **'Please enter both email and password'**
  String get emptyEmailPassError;

  /// No description provided for @invalidEmailError.
  ///
  /// In en, this message translates to:
  /// **'Invalid email format'**
  String get invalidEmailError;

  /// No description provided for @splashErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: '**
  String get splashErrorMessage;

  /// No description provided for @retryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;

  /// No description provided for @firebaseErrorInvalidCredential.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password'**
  String get firebaseErrorInvalidCredential;

  /// No description provided for @firebaseErrorUserDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled'**
  String get firebaseErrorUserDisabled;

  /// No description provided for @firebaseErrorTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many failed attempts. Please try again later'**
  String get firebaseErrorTooManyRequests;

  /// No description provided for @firebaseErrorEmailAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'This email is already in use'**
  String get firebaseErrorEmailAlreadyInUse;

  /// No description provided for @firebaseErrorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak'**
  String get firebaseErrorWeakPassword;

  /// No description provided for @firebaseErrorDefault.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed'**
  String get firebaseErrorDefault;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error, please check your connection'**
  String get networkError;

  /// No description provided for @connectionTimeoutError.
  ///
  /// In en, this message translates to:
  /// **'Connection timeout, please try again'**
  String get connectionTimeoutError;

  /// No description provided for @registerFailureDefault.
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get registerFailureDefault;

  /// No description provided for @loginFailureDefault.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailureDefault;

  /// No description provided for @loginCancelledError.
  ///
  /// In en, this message translates to:
  /// **'Login was cancelled'**
  String get loginCancelledError;

  /// No description provided for @firebaseErrorAccountExistsWithDifferentCredential.
  ///
  /// In en, this message translates to:
  /// **'An account already exists with this email using a different sign-in method'**
  String get firebaseErrorAccountExistsWithDifferentCredential;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabCart.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get tabCart;

  /// No description provided for @tabHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get tabHistory;

  /// No description provided for @tabProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tabProfile;

  /// No description provided for @homePromoTitle.
  ///
  /// In en, this message translates to:
  /// **'Hot TuHu Bread!'**
  String get homePromoTitle;

  /// No description provided for @homePromoSub.
  ///
  /// In en, this message translates to:
  /// **'Enjoy the taste of delicious traditional crispy bread today.'**
  String get homePromoSub;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home Feed Frame'**
  String get homeTitle;

  /// No description provided for @homeBodyPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'The bread list and content will be designed here as per your request.'**
  String get homeBodyPlaceholder;

  /// No description provided for @cartTitle.
  ///
  /// In en, this message translates to:
  /// **'My Cart'**
  String get cartTitle;

  /// No description provided for @cartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Empty Cart'**
  String get cartEmpty;

  /// No description provided for @cartEmptySub.
  ///
  /// In en, this message translates to:
  /// **'Add some crispy breads to start shopping.'**
  String get cartEmptySub;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'Order History'**
  String get historyTitle;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No Orders Yet'**
  String get historyEmpty;

  /// No description provided for @historyEmptySub.
  ///
  /// In en, this message translates to:
  /// **'Your bread ordering history will be shown here.'**
  String get historyEmptySub;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'User Profile'**
  String get profileTitle;

  /// No description provided for @guestUser.
  ///
  /// In en, this message translates to:
  /// **'TuHu Guest'**
  String get guestUser;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
