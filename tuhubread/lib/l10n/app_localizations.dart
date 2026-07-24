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

  /// No description provided for @cartAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to add item to cart'**
  String get cartAddFailed;

  /// No description provided for @cartItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String cartItemsCount(String count);

  /// No description provided for @cartClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get cartClearAll;

  /// No description provided for @cartClearAllConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove all items from your cart?'**
  String get cartClearAllConfirm;

  /// No description provided for @cartCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cartCancel;

  /// No description provided for @cartSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get cartSubtotal;

  /// No description provided for @cartCheckout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get cartCheckout;

  /// No description provided for @cartVariantLabel.
  ///
  /// In en, this message translates to:
  /// **'Variant'**
  String get cartVariantLabel;

  /// No description provided for @cartOptionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get cartOptionsLabel;

  /// No description provided for @cartRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get cartRemove;

  /// No description provided for @cartRemoveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove item?'**
  String get cartRemoveConfirmTitle;

  /// No description provided for @cartRemoveConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove \"{productName}\" from your cart?'**
  String cartRemoveConfirmMessage(String productName);

  /// No description provided for @cartRemoveConfirmBtn.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get cartRemoveConfirmBtn;

  /// No description provided for @cartSuggestionTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a drink to your order?'**
  String get cartSuggestionTitle;

  /// No description provided for @checkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkoutTitle;

  /// No description provided for @checkoutAddressSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Delivery Address'**
  String get checkoutAddressSectionTitle;

  /// No description provided for @checkoutChangeAddress.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get checkoutChangeAddress;

  /// No description provided for @checkoutNoAddressTitle.
  ///
  /// In en, this message translates to:
  /// **'No delivery address'**
  String get checkoutNoAddressTitle;

  /// No description provided for @checkoutAddAddressButton.
  ///
  /// In en, this message translates to:
  /// **'Add delivery address'**
  String get checkoutAddAddressButton;

  /// No description provided for @checkoutDeliveryOptionSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Delivery Option'**
  String get checkoutDeliveryOptionSectionTitle;

  /// No description provided for @checkoutOrderSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Order Items'**
  String get checkoutOrderSectionTitle;

  /// No description provided for @checkoutSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get checkoutSubtotal;

  /// No description provided for @checkoutDeliveryFee.
  ///
  /// In en, this message translates to:
  /// **'Delivery Fee'**
  String get checkoutDeliveryFee;

  /// No description provided for @checkoutTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get checkoutTotal;

  /// No description provided for @checkoutContinueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue to Payment'**
  String get checkoutContinueButton;

  /// No description provided for @checkoutSelectAddressError.
  ///
  /// In en, this message translates to:
  /// **'Please select a delivery address'**
  String get checkoutSelectAddressError;

  /// No description provided for @deliveryOptionPriorityLabel.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get deliveryOptionPriorityLabel;

  /// No description provided for @deliveryOptionPriorityDesc.
  ///
  /// In en, this message translates to:
  /// **'Fastest, within 30 minutes'**
  String get deliveryOptionPriorityDesc;

  /// No description provided for @deliveryOptionStandardLabel.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get deliveryOptionStandardLabel;

  /// No description provided for @deliveryOptionStandardDesc.
  ///
  /// In en, this message translates to:
  /// **'Delivered within 1 hour'**
  String get deliveryOptionStandardDesc;

  /// No description provided for @deliveryOptionSavingLabel.
  ///
  /// In en, this message translates to:
  /// **'Saving'**
  String get deliveryOptionSavingLabel;

  /// No description provided for @deliveryOptionSavingDesc.
  ///
  /// In en, this message translates to:
  /// **'Delivered in 2-3 hours, free shipping'**
  String get deliveryOptionSavingDesc;

  /// No description provided for @paymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentTitle;

  /// No description provided for @paymentMethodSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Payment Method'**
  String get paymentMethodSectionTitle;

  /// No description provided for @paymentMethodCash.
  ///
  /// In en, this message translates to:
  /// **'Payment on Delivery'**
  String get paymentMethodCash;

  /// No description provided for @paymentMethodVnpay.
  ///
  /// In en, this message translates to:
  /// **'VNPAY'**
  String get paymentMethodVnpay;

  /// No description provided for @paymentMethodMomo.
  ///
  /// In en, this message translates to:
  /// **'MoMo Wallet'**
  String get paymentMethodMomo;

  /// No description provided for @paymentMethodZalopay.
  ///
  /// In en, this message translates to:
  /// **'ZaloPay Wallet'**
  String get paymentMethodZalopay;

  /// No description provided for @paymentMethodOnlineNote.
  ///
  /// In en, this message translates to:
  /// **'Online payment gateway is coming soon. Your order will still be placed and you can pay on delivery for now.'**
  String get paymentMethodOnlineNote;

  /// No description provided for @paymentOrderNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note for the shop (optional)'**
  String get paymentOrderNoteLabel;

  /// No description provided for @paymentOrderNoteHint.
  ///
  /// In en, this message translates to:
  /// **'E.g. leave at the door, call before arriving...'**
  String get paymentOrderNoteHint;

  /// No description provided for @paymentPlaceOrderButton.
  ///
  /// In en, this message translates to:
  /// **'Place Order'**
  String get paymentPlaceOrderButton;

  /// No description provided for @paymentOrderSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Order placed successfully!'**
  String get paymentOrderSuccessTitle;

  /// No description provided for @paymentOrderSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Your order {code} has been placed.'**
  String paymentOrderSuccessMessage(String code);

  /// No description provided for @paymentOrderFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to place order'**
  String get paymentOrderFailed;

  /// No description provided for @paymentBackToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get paymentBackToHome;

  /// No description provided for @checkoutVoucherSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Discounts & Vouchers'**
  String get checkoutVoucherSectionTitle;

  /// No description provided for @checkoutVoucherChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get checkoutVoucherChange;

  /// No description provided for @checkoutVoucherSelect.
  ///
  /// In en, this message translates to:
  /// **'Select Code'**
  String get checkoutVoucherSelect;

  /// No description provided for @checkoutVoucherEligibleCount.
  ///
  /// In en, this message translates to:
  /// **'You have {count} eligible vouchers'**
  String checkoutVoucherEligibleCount(int count);

  /// No description provided for @checkoutVoucherChoosePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Select or enter promo code'**
  String get checkoutVoucherChoosePlaceholder;

  /// No description provided for @checkoutVoucherApplied.
  ///
  /// In en, this message translates to:
  /// **'Discount applied: -{amount}'**
  String checkoutVoucherApplied(String amount);

  /// No description provided for @checkoutVoucherNoEligible.
  ///
  /// In en, this message translates to:
  /// **'No eligible vouchers for this order'**
  String get checkoutVoucherNoEligible;

  /// No description provided for @checkoutVoucherDiscountPercent.
  ///
  /// In en, this message translates to:
  /// **'Get {value}% off'**
  String checkoutVoucherDiscountPercent(num value);

  /// No description provided for @checkoutVoucherDiscountPercentMax.
  ///
  /// In en, this message translates to:
  /// **'Get {value}% off, max {max}'**
  String checkoutVoucherDiscountPercentMax(num value, String max);

  /// No description provided for @checkoutVoucherDiscountAmount.
  ///
  /// In en, this message translates to:
  /// **'Get {value} off'**
  String checkoutVoucherDiscountAmount(String value);

  /// No description provided for @checkoutVoucherFreeShipping.
  ///
  /// In en, this message translates to:
  /// **'Free shipping'**
  String get checkoutVoucherFreeShipping;

  /// No description provided for @checkoutVoucherMinOrder.
  ///
  /// In en, this message translates to:
  /// **'Min order: {value}'**
  String checkoutVoucherMinOrder(String value);

  /// No description provided for @checkoutVoucherDoNotUse.
  ///
  /// In en, this message translates to:
  /// **'Do not use Voucher'**
  String get checkoutVoucherDoNotUse;

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

  /// No description provided for @homeShopBranch.
  ///
  /// In en, this message translates to:
  /// **'Shop Branches'**
  String get homeShopBranch;

  /// No description provided for @homeDeselect.
  ///
  /// In en, this message translates to:
  /// **'Deselect'**
  String get homeDeselect;

  /// No description provided for @homeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search bread, drinks...'**
  String get homeSearchHint;

  /// No description provided for @homePromoForYou.
  ///
  /// In en, this message translates to:
  /// **'Promotions For You'**
  String get homePromoForYou;

  /// No description provided for @homeExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get homeExpired;

  /// No description provided for @homeFlash.
  ///
  /// In en, this message translates to:
  /// **'FLASH'**
  String get homeFlash;

  /// No description provided for @homeDiscountFormat.
  ///
  /// In en, this message translates to:
  /// **'Get {discount} off • Min order {minOrder}'**
  String homeDiscountFormat(Object discount, Object minOrder);

  /// No description provided for @homeDiscountPercentFormat.
  ///
  /// In en, this message translates to:
  /// **'Get {discount}% off • Max discount {maxDiscount}'**
  String homeDiscountPercentFormat(Object discount, Object maxDiscount);

  /// No description provided for @homeClaimedVoucherSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Saved code \"{code}\" to wallet!'**
  String homeClaimedVoucherSnackbar(Object code);

  /// No description provided for @homeClaimed.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get homeClaimed;

  /// No description provided for @homeClaimVoucher.
  ///
  /// In en, this message translates to:
  /// **'Save Code'**
  String get homeClaimVoucher;

  /// No description provided for @homeBestSellersBranch.
  ///
  /// In en, this message translates to:
  /// **'Best Sellers at Branch'**
  String get homeBestSellersBranch;

  /// No description provided for @homeBestSellersGlobal.
  ///
  /// In en, this message translates to:
  /// **'Best Sellers'**
  String get homeBestSellersGlobal;

  /// No description provided for @homeSalesBranch.
  ///
  /// In en, this message translates to:
  /// **'On Sale at Branch'**
  String get homeSalesBranch;

  /// No description provided for @homeSalesGlobal.
  ///
  /// In en, this message translates to:
  /// **'On Sale'**
  String get homeSalesGlobal;

  /// No description provided for @homeAllBranches.
  ///
  /// In en, this message translates to:
  /// **'All Branches'**
  String get homeAllBranches;

  /// No description provided for @homeCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get homeCategories;

  /// No description provided for @homeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get homeAll;

  /// No description provided for @homeShopMenu.
  ///
  /// In en, this message translates to:
  /// **'Shop\'s Menu'**
  String get homeShopMenu;

  /// No description provided for @homeAllItems.
  ///
  /// In en, this message translates to:
  /// **'All Items'**
  String get homeAllItems;

  /// No description provided for @homeNoProductsFound.
  ///
  /// In en, this message translates to:
  /// **'No matching products found'**
  String get homeNoProductsFound;

  /// No description provided for @homeRemainingVouchers.
  ///
  /// In en, this message translates to:
  /// **'{count} vouchers left'**
  String homeRemainingVouchers(Object count);

  /// No description provided for @homeSoldOutVouchers.
  ///
  /// In en, this message translates to:
  /// **'Sold out'**
  String get homeSoldOutVouchers;

  /// No description provided for @detailTitle.
  ///
  /// In en, this message translates to:
  /// **'Product Detail'**
  String get detailTitle;

  /// No description provided for @detailSelectSize.
  ///
  /// In en, this message translates to:
  /// **'Select Size'**
  String get detailSelectSize;

  /// No description provided for @detailExtraOptions.
  ///
  /// In en, this message translates to:
  /// **'Extra Options'**
  String get detailExtraOptions;

  /// No description provided for @detailAddToCart.
  ///
  /// In en, this message translates to:
  /// **'Add to Cart'**
  String get detailAddToCart;

  /// No description provided for @detailDescription.
  ///
  /// In en, this message translates to:
  /// **'Product Description'**
  String get detailDescription;

  /// No description provided for @detailPrepTime.
  ///
  /// In en, this message translates to:
  /// **'{minutes} mins prep'**
  String detailPrepTime(Object minutes);

  /// No description provided for @detailTotalPrice.
  ///
  /// In en, this message translates to:
  /// **'Total Price'**
  String get detailTotalPrice;

  /// No description provided for @detailAddedToCart.
  ///
  /// In en, this message translates to:
  /// **'Added to cart!'**
  String get detailAddedToCart;

  /// No description provided for @detailBuyNow.
  ///
  /// In en, this message translates to:
  /// **'Buy Now'**
  String get detailBuyNow;

  /// No description provided for @detailQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get detailQuantity;

  /// No description provided for @detailBuyNowSuccess.
  ///
  /// In en, this message translates to:
  /// **'Proceeding to checkout now!'**
  String get detailBuyNowSuccess;

  /// No description provided for @detailShopSection.
  ///
  /// In en, this message translates to:
  /// **'Provided by Branch'**
  String get detailShopSection;

  /// No description provided for @detailReviewsSection.
  ///
  /// In en, this message translates to:
  /// **'Customer Reviews ({count})'**
  String detailReviewsSection(Object count);

  /// No description provided for @detailNoReviews.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet for this product'**
  String get detailNoReviews;

  /// No description provided for @detailShopPhone.
  ///
  /// In en, this message translates to:
  /// **'Branch Hotline: {phone}'**
  String detailShopPhone(Object phone);

  /// No description provided for @detailNoRatingYet.
  ///
  /// In en, this message translates to:
  /// **'No ratings yet'**
  String get detailNoRatingYet;

  /// No description provided for @detailOtherShopsSection.
  ///
  /// In en, this message translates to:
  /// **'Other branches selling this'**
  String get detailOtherShopsSection;

  /// No description provided for @orderStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get orderStatusPending;

  /// No description provided for @orderStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get orderStatusConfirmed;

  /// No description provided for @orderStatusPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get orderStatusPreparing;

  /// No description provided for @orderStatusDelivering.
  ///
  /// In en, this message translates to:
  /// **'Delivering'**
  String get orderStatusDelivering;

  /// No description provided for @orderStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get orderStatusCompleted;

  /// No description provided for @orderStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get orderStatusCancelled;

  /// No description provided for @cancelOrderButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel Order'**
  String get cancelOrderButton;

  /// No description provided for @cancelOrderConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Cancellation'**
  String get cancelOrderConfirmTitle;

  /// No description provided for @cancelOrderConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this order?'**
  String get cancelOrderConfirmMessage;

  /// No description provided for @cancelSuccess.
  ///
  /// In en, this message translates to:
  /// **'Order cancelled successfully!'**
  String get cancelSuccess;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @orderCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Order Code: '**
  String get orderCodeLabel;

  /// No description provided for @orderDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Order Date: '**
  String get orderDateLabel;

  /// No description provided for @paymentMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethodLabel;

  /// No description provided for @paymentStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Status'**
  String get paymentStatusLabel;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivery Address'**
  String get addressLabel;

  /// No description provided for @itemsTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Items Total'**
  String get itemsTotalLabel;

  /// No description provided for @deliveryFeeLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivery Fee'**
  String get deliveryFeeLabel;

  /// No description provided for @discountLabel.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discountLabel;

  /// No description provided for @totalAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get totalAmountLabel;

  /// No description provided for @paymentMethodBank.
  ///
  /// In en, this message translates to:
  /// **'Bank Transfer'**
  String get paymentMethodBank;

  /// No description provided for @paymentStatusUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get paymentStatusUnpaid;

  /// No description provided for @paymentStatusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paymentStatusPaid;

  /// No description provided for @paymentStatusRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get paymentStatusRefunded;

  /// No description provided for @profileMyOrders.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get profileMyOrders;

  /// No description provided for @profileMyOrdersSub.
  ///
  /// In en, this message translates to:
  /// **'Track and manage your orders'**
  String get profileMyOrdersSub;

  /// No description provided for @profileAddresses.
  ///
  /// In en, this message translates to:
  /// **'Shipping Addresses'**
  String get profileAddresses;

  /// No description provided for @profileAddressesSub.
  ///
  /// In en, this message translates to:
  /// **'Manage your delivery addresses'**
  String get profileAddressesSub;

  /// No description provided for @profileMyVouchers.
  ///
  /// In en, this message translates to:
  /// **'My Vouchers'**
  String get profileMyVouchers;

  /// No description provided for @profileMyVouchersSub.
  ///
  /// In en, this message translates to:
  /// **'View saved discount codes'**
  String get profileMyVouchersSub;

  /// No description provided for @profileEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get profileEditProfile;

  /// No description provided for @profileEditProfileSub.
  ///
  /// In en, this message translates to:
  /// **'Update your personal information'**
  String get profileEditProfileSub;

  /// No description provided for @profileChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get profileChangePassword;

  /// No description provided for @profileChangePasswordSub.
  ///
  /// In en, this message translates to:
  /// **'Keep your account secure'**
  String get profileChangePasswordSub;

  /// No description provided for @profileSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get profileSettings;

  /// No description provided for @profileSettingsSub.
  ///
  /// In en, this message translates to:
  /// **'Notifications, language and more'**
  String get profileSettingsSub;

  /// No description provided for @profileHelpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get profileHelpCenter;

  /// No description provided for @profileHelpCenterSub.
  ///
  /// In en, this message translates to:
  /// **'FAQs and customer support'**
  String get profileHelpCenterSub;

  /// No description provided for @profileLogoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get profileLogoutConfirmTitle;

  /// No description provided for @profileLogoutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get profileLogoutConfirmMessage;

  /// No description provided for @profileCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get profileCancel;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileTitle;

  /// No description provided for @editProfilePhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get editProfilePhoneHint;

  /// No description provided for @editProfileChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change Photo'**
  String get editProfileChangePhoto;

  /// No description provided for @editProfileSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get editProfileSaveButton;

  /// No description provided for @editProfileSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get editProfileSaveSuccess;

  /// No description provided for @editProfileSaveError.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile, please try again'**
  String get editProfileSaveError;

  /// No description provided for @editProfileAvatarError.
  ///
  /// In en, this message translates to:
  /// **'Failed to update avatar, please try again'**
  String get editProfileAvatarError;

  /// No description provided for @addressesTitle.
  ///
  /// In en, this message translates to:
  /// **'Shipping Addresses'**
  String get addressesTitle;

  /// No description provided for @addressesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No addresses yet'**
  String get addressesEmptyTitle;

  /// No description provided for @addressesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add a delivery address to get started'**
  String get addressesEmptySubtitle;

  /// No description provided for @addressAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add New Address'**
  String get addressAddButton;

  /// No description provided for @addressDefaultLabel.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get addressDefaultLabel;

  /// No description provided for @addressSetDefaultAction.
  ///
  /// In en, this message translates to:
  /// **'Set as default'**
  String get addressSetDefaultAction;

  /// No description provided for @addressEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get addressEditAction;

  /// No description provided for @addressDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get addressDeleteAction;

  /// No description provided for @addressDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Address'**
  String get addressDeleteConfirmTitle;

  /// No description provided for @addressDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this address?'**
  String get addressDeleteConfirmMessage;

  /// No description provided for @addressFormAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Address'**
  String get addressFormAddTitle;

  /// No description provided for @addressFormEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Address'**
  String get addressFormEditTitle;

  /// No description provided for @addressReceiverNameHint.
  ///
  /// In en, this message translates to:
  /// **'Receiver Name'**
  String get addressReceiverNameHint;

  /// No description provided for @addressReceiverPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Receiver Phone'**
  String get addressReceiverPhoneHint;

  /// No description provided for @addressProvinceHint.
  ///
  /// In en, this message translates to:
  /// **'Province / City'**
  String get addressProvinceHint;

  /// No description provided for @addressWardHint.
  ///
  /// In en, this message translates to:
  /// **'Ward / Commune'**
  String get addressWardHint;

  /// No description provided for @addressStreetHint.
  ///
  /// In en, this message translates to:
  /// **'House number, street name'**
  String get addressStreetHint;

  /// No description provided for @addressLabelHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get addressLabelHome;

  /// No description provided for @addressLabelCompany.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get addressLabelCompany;

  /// No description provided for @addressLabelOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get addressLabelOther;

  /// No description provided for @addressUseCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use current location'**
  String get addressUseCurrentLocation;

  /// No description provided for @addressLocationDetecting.
  ///
  /// In en, this message translates to:
  /// **'Detecting your location...'**
  String get addressLocationDetecting;

  /// No description provided for @addressLocationServiceDisabled.
  ///
  /// In en, this message translates to:
  /// **'Please enable location services (GPS)'**
  String get addressLocationServiceDisabled;

  /// No description provided for @addressLocationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission is required'**
  String get addressLocationPermissionDenied;

  /// No description provided for @addressLocationPermissionDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location permission was permanently denied, please enable it in Settings'**
  String get addressLocationPermissionDeniedForever;

  /// No description provided for @addressLocationFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not detect your location, please try again'**
  String get addressLocationFailed;

  /// No description provided for @addressLocationDetected.
  ///
  /// In en, this message translates to:
  /// **'Location detected, please review the details'**
  String get addressLocationDetected;

  /// No description provided for @selectAddressTitle.
  ///
  /// In en, this message translates to:
  /// **'Delivery Address'**
  String get selectAddressTitle;

  /// No description provided for @selectAddressSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search location'**
  String get selectAddressSearchHint;

  /// No description provided for @selectAddressSavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved Addresses'**
  String get selectAddressSavedTitle;

  /// No description provided for @selectAddressEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved addresses yet'**
  String get selectAddressEmpty;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get notificationsFilterAll;

  /// No description provided for @notificationsFilterOrder.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get notificationsFilterOrder;

  /// No description provided for @notificationsFilterPromotion.
  ///
  /// In en, this message translates to:
  /// **'Promotions'**
  String get notificationsFilterPromotion;

  /// No description provided for @notificationsFilterSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get notificationsFilterSystem;

  /// No description provided for @notificationsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get notificationsEmptyTitle;

  /// No description provided for @notificationsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'New notifications will appear here'**
  String get notificationsEmptySubtitle;

  /// No description provided for @notificationsJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get notificationsJustNow;

  /// No description provided for @notificationsMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String notificationsMinutesAgo(int count);

  /// No description provided for @notificationsHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String notificationsHoursAgo(int count);

  /// No description provided for @notificationsDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String notificationsDaysAgo(int count);

  /// No description provided for @addressSetDefaultLabel.
  ///
  /// In en, this message translates to:
  /// **'Set as default address'**
  String get addressSetDefaultLabel;

  /// No description provided for @addressSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save Address'**
  String get addressSaveButton;

  /// No description provided for @addressSaveError.
  ///
  /// In en, this message translates to:
  /// **'Failed to save address, please try again'**
  String get addressSaveError;

  /// No description provided for @addressDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete address, please try again'**
  String get addressDeleteError;

  /// No description provided for @myVouchersTitle.
  ///
  /// In en, this message translates to:
  /// **'My Vouchers'**
  String get myVouchersTitle;

  /// No description provided for @myVouchersEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No vouchers saved yet'**
  String get myVouchersEmptyTitle;

  /// No description provided for @myVouchersEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save vouchers from the home page to see them here'**
  String get myVouchersEmptySubtitle;

  /// No description provided for @myVouchersUsedLabel.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get myVouchersUsedLabel;

  /// No description provided for @myVouchersExpiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get myVouchersExpiredLabel;

  /// No description provided for @myVouchersAvailableLabel.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get myVouchersAvailableLabel;

  /// No description provided for @voucherEnterCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter voucher code'**
  String get voucherEnterCodeHint;

  /// No description provided for @voucherRedeemSuccess.
  ///
  /// In en, this message translates to:
  /// **'Voucher applied successfully'**
  String get voucherRedeemSuccess;

  /// No description provided for @voucherDiscountLabel.
  ///
  /// In en, this message translates to:
  /// **'DISCOUNT'**
  String get voucherDiscountLabel;

  /// No description provided for @voucherFreeShipLabel.
  ///
  /// In en, this message translates to:
  /// **'FREE\nSHIP'**
  String get voucherFreeShipLabel;

  /// No description provided for @voucherMinOrder.
  ///
  /// In en, this message translates to:
  /// **'Min. order {amount}'**
  String voucherMinOrder(String amount);

  /// No description provided for @voucherUseNowButton.
  ///
  /// In en, this message translates to:
  /// **'Use now'**
  String get voucherUseNowButton;

  /// No description provided for @voucherUseAtCheckoutMsg.
  ///
  /// In en, this message translates to:
  /// **'This voucher will be applied at checkout'**
  String get voucherUseAtCheckoutMsg;

  /// No description provided for @voucherAvailableSection.
  ///
  /// In en, this message translates to:
  /// **'Available Vouchers'**
  String get voucherAvailableSection;

  /// No description provided for @voucherSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get voucherSaveButton;

  /// No description provided for @myVouchersExpiresOn.
  ///
  /// In en, this message translates to:
  /// **'Expires on {date}'**
  String myVouchersExpiresOn(String date);

  /// No description provided for @changePasswordNotApplicable.
  ///
  /// In en, this message translates to:
  /// **'Change password is not available for accounts signed in with Google/Facebook'**
  String get changePasswordNotApplicable;

  /// No description provided for @changePasswordCurrentHint.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get changePasswordCurrentHint;

  /// No description provided for @changePasswordNewHint.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get changePasswordNewHint;

  /// No description provided for @changePasswordConfirmHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get changePasswordConfirmHint;

  /// No description provided for @changePasswordSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get changePasswordSaveButton;

  /// No description provided for @changePasswordSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully'**
  String get changePasswordSuccess;

  /// No description provided for @changePasswordWrongCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current password is incorrect'**
  String get changePasswordWrongCurrent;

  /// No description provided for @changePasswordWeak.
  ///
  /// In en, this message translates to:
  /// **'New password is too weak'**
  String get changePasswordWeak;

  /// No description provided for @changePasswordDefaultError.
  ///
  /// In en, this message translates to:
  /// **'Failed to update password, please try again'**
  String get changePasswordDefaultError;

  /// No description provided for @settingsLanguageSection.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageSection;

  /// No description provided for @settingsLanguageVietnamese.
  ///
  /// In en, this message translates to:
  /// **'Vietnamese'**
  String get settingsLanguageVietnamese;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @helpCenterFaqSection.
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions'**
  String get helpCenterFaqSection;

  /// No description provided for @helpCenterContactSection.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get helpCenterContactSection;

  /// No description provided for @helpCenterFaq1Question.
  ///
  /// In en, this message translates to:
  /// **'How do I place an order?'**
  String get helpCenterFaq1Question;

  /// No description provided for @helpCenterFaq1Answer.
  ///
  /// In en, this message translates to:
  /// **'Browse a shop\'s menu, add items to your cart, choose a delivery address and payment method, then confirm your order.'**
  String get helpCenterFaq1Answer;

  /// No description provided for @helpCenterFaq2Question.
  ///
  /// In en, this message translates to:
  /// **'How can I track my order?'**
  String get helpCenterFaq2Question;

  /// No description provided for @helpCenterFaq2Answer.
  ///
  /// In en, this message translates to:
  /// **'Open the History tab to see the status of your current and past orders.'**
  String get helpCenterFaq2Answer;

  /// No description provided for @helpCenterFaq3Question.
  ///
  /// In en, this message translates to:
  /// **'How do I use a voucher?'**
  String get helpCenterFaq3Question;

  /// No description provided for @helpCenterFaq3Answer.
  ///
  /// In en, this message translates to:
  /// **'Save a voucher from the home page or My Vouchers screen, then select it at checkout to apply the discount.'**
  String get helpCenterFaq3Answer;

  /// No description provided for @helpCenterFaq4Question.
  ///
  /// In en, this message translates to:
  /// **'How do I change my delivery address?'**
  String get helpCenterFaq4Question;

  /// No description provided for @helpCenterFaq4Answer.
  ///
  /// In en, this message translates to:
  /// **'Go to Profile > Shipping Addresses to add, edit or set a default delivery address.'**
  String get helpCenterFaq4Answer;

  /// No description provided for @helpCenterCallSupport.
  ///
  /// In en, this message translates to:
  /// **'Call Support'**
  String get helpCenterCallSupport;

  /// No description provided for @helpCenterEmailSupport.
  ///
  /// In en, this message translates to:
  /// **'Email Support'**
  String get helpCenterEmailSupport;
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
