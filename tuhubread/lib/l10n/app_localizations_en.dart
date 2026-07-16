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
  String get orderStatusPending => 'Pending';

  @override
  String get orderStatusConfirmed => 'Confirmed';

  @override
  String get orderStatusPreparing => 'Preparing';

  @override
  String get orderStatusDelivering => 'Delivering';

  @override
  String get orderStatusCompleted => 'Completed';

  @override
  String get orderStatusCancelled => 'Cancelled';

  @override
  String get cancelOrderButton => 'Cancel Order';

  @override
  String get cancelOrderConfirmTitle => 'Confirm Cancellation';

  @override
  String get cancelOrderConfirmMessage =>
      'Are you sure you want to cancel this order?';

  @override
  String get cancelSuccess => 'Order cancelled successfully!';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get orderCodeLabel => 'Order Code: ';

  @override
  String get orderDateLabel => 'Order Date: ';

  @override
  String get paymentMethodLabel => 'Payment Method';

  @override
  String get paymentStatusLabel => 'Payment Status';

  @override
  String get addressLabel => 'Delivery Address';

  @override
  String get itemsTotalLabel => 'Items Total';

  @override
  String get deliveryFeeLabel => 'Delivery Fee';

  @override
  String get discountLabel => 'Discount';

  @override
  String get totalAmountLabel => 'Total Amount';

  @override
  String get paymentMethodCash => 'Cash';

  @override
  String get paymentMethodMomo => 'MoMo Wallet';

  @override
  String get paymentMethodBank => 'Bank Transfer';

  @override
  String get paymentMethodVnpay => 'VNPAY';

  @override
  String get paymentStatusUnpaid => 'Unpaid';

  @override
  String get paymentStatusPaid => 'Paid';

  @override
  String get paymentStatusRefunded => 'Refunded';
}
