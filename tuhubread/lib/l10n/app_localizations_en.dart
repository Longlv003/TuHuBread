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

  @override
  String get tabHome => 'Home';

  @override
  String get tabCart => 'Cart';

  @override
  String get tabHistory => 'History';

  @override
  String get tabProfile => 'Profile';

  @override
  String get homePromoTitle => 'Hot TuHu Bread!';

  @override
  String get homePromoSub =>
      'Enjoy the taste of delicious traditional crispy bread today.';

  @override
  String get homeTitle => 'Home Feed Frame';

  @override
  String get homeBodyPlaceholder =>
      'The bread list and content will be designed here as per your request.';

  @override
  String get cartTitle => 'My Cart';

  @override
  String get cartEmpty => 'Empty Cart';

  @override
  String get cartEmptySub => 'Add some crispy breads to start shopping.';

  @override
  String get historyTitle => 'Order History';

  @override
  String get historyEmpty => 'No Orders Yet';

  @override
  String get historyEmptySub =>
      'Your bread ordering history will be shown here.';

  @override
  String get profileTitle => 'User Profile';

  @override
  String get guestUser => 'TuHu Guest';

  @override
  String get homeShopBranch => 'Shop Branches';

  @override
  String get homeDeselect => 'Deselect';

  @override
  String get homeSearchHint => 'Search bread, drinks...';

  @override
  String get homePromoForYou => 'Promotions For You';

  @override
  String get homeExpired => 'Expired';

  @override
  String get homeFlash => 'FLASH';

  @override
  String homeDiscountFormat(Object discount, Object minOrder) {
    return 'Get $discount off • Min order $minOrder';
  }

  @override
  String homeDiscountPercentFormat(Object discount, Object maxDiscount) {
    return 'Get $discount% off • Max discount $maxDiscount';
  }

  @override
  String homeClaimedVoucherSnackbar(Object code) {
    return 'Saved code \"$code\" to wallet!';
  }

  @override
  String get homeClaimed => 'Saved';

  @override
  String get homeClaimVoucher => 'Save Code';

  @override
  String get homeBestSellersBranch => 'Best Sellers at Branch';

  @override
  String get homeBestSellersGlobal => 'Best Sellers';

  @override
  String get homeSalesBranch => 'On Sale at Branch';

  @override
  String get homeSalesGlobal => 'On Sale';

  @override
  String get homeAllBranches => 'All Branches';

  @override
  String get homeCategories => 'Categories';

  @override
  String get homeAll => 'All';

  @override
  String get homeShopMenu => 'Shop\'s Menu';

  @override
  String get homeAllItems => 'All Items';

  @override
  String get homeNoProductsFound => 'No matching products found';

  @override
  String homeRemainingVouchers(Object count) {
    return '$count vouchers left';
  }

  @override
  String get homeSoldOutVouchers => 'Sold out';

  @override
  String get detailTitle => 'Product Detail';

  @override
  String get detailSelectSize => 'Select Size';

  @override
  String get detailExtraOptions => 'Extra Options';

  @override
  String get detailAddToCart => 'Add to Cart';

  @override
  String get detailDescription => 'Product Description';

  @override
  String detailPrepTime(Object minutes) {
    return '$minutes mins prep';
  }

  @override
  String get detailTotalPrice => 'Total Price';

  @override
  String get detailAddedToCart => 'Added to cart!';

  @override
  String get detailBuyNow => 'Buy Now';

  @override
  String get detailQuantity => 'Quantity';

  @override
  String get detailBuyNowSuccess => 'Proceeding to checkout now!';

  @override
  String get detailShopSection => 'Provided by Branch';

  @override
  String detailReviewsSection(Object count) {
    return 'Customer Reviews ($count)';
  }

  @override
  String get detailNoReviews => 'No reviews yet for this product';

  @override
  String detailShopPhone(Object phone) {
    return 'Branch Hotline: $phone';
  }

  @override
  String get detailNoRatingYet => 'No ratings yet';

  @override
  String get detailOtherShopsSection => 'Other branches selling this';

  @override
  String get profileMyOrders => 'My Orders';

  @override
  String get profileMyOrdersSub => 'Track and manage your orders';

  @override
  String get profileAddresses => 'Shipping Addresses';

  @override
  String get profileAddressesSub => 'Manage your delivery addresses';

  @override
  String get profileMyVouchers => 'My Vouchers';

  @override
  String get profileMyVouchersSub => 'View saved discount codes';

  @override
  String get profileEditProfile => 'Edit Profile';

  @override
  String get profileEditProfileSub => 'Update your personal information';

  @override
  String get profileChangePassword => 'Change Password';

  @override
  String get profileChangePasswordSub => 'Keep your account secure';

  @override
  String get profileSettings => 'Settings';

  @override
  String get profileSettingsSub => 'Notifications, language and more';

  @override
  String get profileHelpCenter => 'Help Center';

  @override
  String get profileHelpCenterSub => 'FAQs and customer support';

  @override
  String get profileLogoutConfirmTitle => 'Sign Out';

  @override
  String get profileLogoutConfirmMessage =>
      'Are you sure you want to sign out?';

  @override
  String get profileCancel => 'Cancel';

  @override
  String get editProfileTitle => 'Edit Profile';

  @override
  String get editProfilePhoneHint => 'Phone Number';

  @override
  String get editProfileChangePhoto => 'Change Photo';

  @override
  String get editProfileSaveButton => 'Save Changes';

  @override
  String get editProfileSaveSuccess => 'Profile updated successfully';

  @override
  String get editProfileSaveError =>
      'Failed to update profile, please try again';

  @override
  String get editProfileAvatarError =>
      'Failed to update avatar, please try again';

  @override
  String get addressesTitle => 'Shipping Addresses';

  @override
  String get addressesEmptyTitle => 'No addresses yet';

  @override
  String get addressesEmptySubtitle => 'Add a delivery address to get started';

  @override
  String get addressAddButton => 'Add New Address';

  @override
  String get addressDefaultLabel => 'Default';

  @override
  String get addressSetDefaultAction => 'Set as default';

  @override
  String get addressEditAction => 'Edit';

  @override
  String get addressDeleteAction => 'Delete';

  @override
  String get addressDeleteConfirmTitle => 'Delete Address';

  @override
  String get addressDeleteConfirmMessage =>
      'Are you sure you want to delete this address?';

  @override
  String get addressFormAddTitle => 'Add Address';

  @override
  String get addressFormEditTitle => 'Edit Address';

  @override
  String get addressReceiverNameHint => 'Receiver Name';

  @override
  String get addressReceiverPhoneHint => 'Receiver Phone';

  @override
  String get addressProvinceHint => 'Province / City';

  @override
  String get addressWardHint => 'Ward / Commune';

  @override
  String get addressStreetHint => 'House number, street name';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsMarkAllRead => 'Mark all as read';

  @override
  String get notificationsFilterAll => 'All';

  @override
  String get notificationsFilterOrder => 'Orders';

  @override
  String get notificationsFilterPromotion => 'Promotions';

  @override
  String get notificationsFilterSystem => 'System';

  @override
  String get notificationsEmptyTitle => 'No notifications';

  @override
  String get notificationsEmptySubtitle => 'New notifications will appear here';

  @override
  String get notificationsJustNow => 'Just now';

  @override
  String notificationsMinutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String notificationsHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String notificationsDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String get addressSetDefaultLabel => 'Set as default address';

  @override
  String get addressSaveButton => 'Save Address';

  @override
  String get addressSaveError => 'Failed to save address, please try again';

  @override
  String get addressDeleteError => 'Failed to delete address, please try again';

  @override
  String get myVouchersTitle => 'My Vouchers';

  @override
  String get myVouchersEmptyTitle => 'No vouchers saved yet';

  @override
  String get myVouchersEmptySubtitle =>
      'Save vouchers from the home page to see them here';

  @override
  String get myVouchersUsedLabel => 'Used';

  @override
  String get myVouchersExpiredLabel => 'Expired';

  @override
  String get myVouchersAvailableLabel => 'Available';

  @override
  String get voucherEnterCodeHint => 'Enter voucher code';

  @override
  String get voucherRedeemSuccess => 'Voucher applied successfully';

  @override
  String get voucherDiscountLabel => 'DISCOUNT';

  @override
  String get voucherFreeShipLabel => 'FREE\nSHIP';

  @override
  String voucherMinOrder(String amount) {
    return 'Min. order $amount';
  }

  @override
  String get voucherUseNowButton => 'Use now';

  @override
  String get voucherUseAtCheckoutMsg =>
      'This voucher will be applied at checkout';

  @override
  String get voucherAvailableSection => 'Available Vouchers';

  @override
  String get voucherSaveButton => 'Save';

  @override
  String myVouchersExpiresOn(String date) {
    return 'Expires on $date';
  }

  @override
  String get changePasswordNotApplicable =>
      'Change password is not available for accounts signed in with Google/Facebook';

  @override
  String get changePasswordCurrentHint => 'Current Password';

  @override
  String get changePasswordNewHint => 'New Password';

  @override
  String get changePasswordConfirmHint => 'Confirm New Password';

  @override
  String get changePasswordSaveButton => 'Update Password';

  @override
  String get changePasswordSuccess => 'Password updated successfully';

  @override
  String get changePasswordWrongCurrent => 'Current password is incorrect';

  @override
  String get changePasswordWeak => 'New password is too weak';

  @override
  String get changePasswordDefaultError =>
      'Failed to update password, please try again';

  @override
  String get settingsLanguageSection => 'Language';

  @override
  String get settingsLanguageVietnamese => 'Vietnamese';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get helpCenterFaqSection => 'Frequently Asked Questions';

  @override
  String get helpCenterContactSection => 'Contact Support';

  @override
  String get helpCenterFaq1Question => 'How do I place an order?';

  @override
  String get helpCenterFaq1Answer =>
      'Browse a shop\'s menu, add items to your cart, choose a delivery address and payment method, then confirm your order.';

  @override
  String get helpCenterFaq2Question => 'How can I track my order?';

  @override
  String get helpCenterFaq2Answer =>
      'Open the History tab to see the status of your current and past orders.';

  @override
  String get helpCenterFaq3Question => 'How do I use a voucher?';

  @override
  String get helpCenterFaq3Answer =>
      'Save a voucher from the home page or My Vouchers screen, then select it at checkout to apply the discount.';

  @override
  String get helpCenterFaq4Question => 'How do I change my delivery address?';

  @override
  String get helpCenterFaq4Answer =>
      'Go to Profile > Shipping Addresses to add, edit or set a default delivery address.';

  @override
  String get helpCenterCallSupport => 'Call Support';

  @override
  String get helpCenterEmailSupport => 'Email Support';
}
