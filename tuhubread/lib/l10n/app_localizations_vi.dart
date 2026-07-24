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

  @override
  String get loginCancelledError => 'Đã hủy đăng nhập';

  @override
  String get firebaseErrorAccountExistsWithDifferentCredential =>
      'Email này đã được sử dụng với một phương thức đăng nhập khác (ví dụ: Google hoặc Mật khẩu)';

  @override
  String get tabHome => '';

  @override
  String get tabCart => '';

  @override
  String get tabHistory => '';

  @override
  String get tabProfile => '';

  @override
  String get homePromoTitle => 'Bánh mì TuHu nóng hổi!';

  @override
  String get homePromoSub =>
      'Thưởng thức hương vị bánh mì truyền thống giòn ngon ngay hôm nay.';

  @override
  String get homeTitle => 'Khung nội dung Trang chủ';

  @override
  String get homeBodyPlaceholder =>
      'Nội dung và danh sách bánh mì sẽ được thiết kế tại đây theo yêu cầu của bạn.';

  @override
  String get cartTitle => 'Giỏ hàng của tôi';

  @override
  String get cartEmpty => 'Giỏ hàng trống';

  @override
  String get cartEmptySub =>
      'Thêm các sản phẩm bánh mì giòn ngon để bắt đầu mua sắm.';

  @override
  String get cartAddFailed => 'Thêm vào giỏ hàng thất bại';

  @override
  String cartItemsCount(String count) {
    return '$count sản phẩm';
  }

  @override
  String get cartClearAll => 'Xóa tất cả';

  @override
  String get cartClearAllConfirm =>
      'Bạn có chắc muốn xóa toàn bộ sản phẩm trong giỏ hàng không?';

  @override
  String get cartCancel => 'Hủy';

  @override
  String get cartSubtotal => 'Tạm tính';

  @override
  String get cartCheckout => 'Thanh toán';

  @override
  String get cartVariantLabel => 'Phân loại';

  @override
  String get cartOptionsLabel => 'Tùy chọn';

  @override
  String get cartRemove => 'Xóa';

  @override
  String get cartRemoveConfirmTitle => 'Xóa sản phẩm?';

  @override
  String cartRemoveConfirmMessage(String productName) {
    return 'Bạn có chắc muốn xóa \"$productName\" khỏi giỏ hàng không?';
  }

  @override
  String get cartRemoveConfirmBtn => 'Xóa';

  @override
  String get cartSuggestionTitle => 'Thêm đồ uống cho đơn hàng?';

  @override
  String get checkoutTitle => 'Thanh toán';

  @override
  String get checkoutAddressSectionTitle => 'Địa chỉ giao hàng';

  @override
  String get checkoutChangeAddress => 'Thay đổi';

  @override
  String get checkoutNoAddressTitle => 'Chưa có địa chỉ giao hàng';

  @override
  String get checkoutAddAddressButton => 'Thêm địa chỉ giao hàng';

  @override
  String get checkoutDeliveryOptionSectionTitle => 'Tùy chọn giao hàng';

  @override
  String get checkoutOrderSectionTitle => 'Sản phẩm đã chọn';

  @override
  String get checkoutSubtotal => 'Tạm tính';

  @override
  String get checkoutDeliveryFee => 'Phí giao hàng';

  @override
  String get checkoutTotal => 'Tổng cộng';

  @override
  String get checkoutContinueButton => 'Tiếp tục thanh toán';

  @override
  String get checkoutSelectAddressError => 'Vui lòng chọn địa chỉ giao hàng';

  @override
  String get deliveryOptionPriorityLabel => 'Ưu tiên';

  @override
  String get deliveryOptionPriorityDesc =>
      'Giao nhanh nhất, trong vòng 30 phút';

  @override
  String get deliveryOptionStandardLabel => 'Nhanh';

  @override
  String get deliveryOptionStandardDesc => 'Giao trong vòng 1 giờ';

  @override
  String get deliveryOptionSavingLabel => 'Tiết kiệm';

  @override
  String get deliveryOptionSavingDesc => 'Giao trong 2-3 giờ, miễn phí ship';

  @override
  String get paymentTitle => 'Phương thức thanh toán';

  @override
  String get paymentMethodSectionTitle => 'Chọn phương thức thanh toán';

  @override
  String get paymentMethodCash => 'Thanh toán khi nhận hàng';

  @override
  String get paymentMethodVnpay => 'VNPAY';

  @override
  String get paymentMethodMomo => 'Ví MoMo';

  @override
  String get paymentMethodZalopay => 'Ví ZaloPay';

  @override
  String get paymentMethodOnlineNote =>
      'Cổng thanh toán trực tuyến đang được phát triển. Đơn hàng vẫn được tạo, bạn có thể thanh toán khi nhận hàng.';

  @override
  String get paymentOrderNoteLabel => 'Ghi chú cho cửa hàng (không bắt buộc)';

  @override
  String get paymentOrderNoteHint => 'VD: để trước cửa, gọi trước khi tới...';

  @override
  String get paymentPlaceOrderButton => 'Đặt hàng';

  @override
  String get paymentOrderSuccessTitle => 'Đặt hàng thành công!';

  @override
  String paymentOrderSuccessMessage(String code) {
    return 'Đơn hàng $code của bạn đã được đặt.';
  }

  @override
  String get paymentOrderFailed => 'Đặt hàng thất bại';

  @override
  String get paymentBackToHome => 'Về trang chủ';

  @override
  String get checkoutVoucherSectionTitle => 'Ưu đãi & Voucher';

  @override
  String get checkoutVoucherChange => 'Chọn lại';

  @override
  String get checkoutVoucherSelect => 'Chọn mã';

  @override
  String checkoutVoucherEligibleCount(int count) {
    return 'Bạn đang có $count voucher phù hợp';
  }

  @override
  String get checkoutVoucherChoosePlaceholder => 'Chọn hoặc nhập mã giảm giá';

  @override
  String checkoutVoucherApplied(String amount) {
    return 'Đã áp dụng giảm -$amount';
  }

  @override
  String get checkoutVoucherNoEligible =>
      'Không có voucher nào đủ điều kiện cho đơn hàng này';

  @override
  String checkoutVoucherDiscountPercent(num value) {
    return 'Giảm $value%';
  }

  @override
  String checkoutVoucherDiscountPercentMax(num value, String max) {
    return 'Giảm $value% tối đa $max';
  }

  @override
  String checkoutVoucherDiscountAmount(String value) {
    return 'Giảm $value';
  }

  @override
  String get checkoutVoucherFreeShipping => 'Miễn phí vận chuyển';

  @override
  String checkoutVoucherMinOrder(String value) {
    return 'Đơn tối thiểu: $value';
  }

  @override
  String get checkoutVoucherDoNotUse => 'Không sử dụng Voucher';

  @override
  String get historyTitle => 'Lịch sử đặt hàng';

  @override
  String get historyEmpty => 'Chưa có đơn hàng nào';

  @override
  String get historyEmptySub =>
      'Lịch sử đặt bánh mì của bạn sẽ hiển thị tại tab này.';

  @override
  String get profileTitle => 'Hồ sơ cá nhân';

  @override
  String get guestUser => 'Khách TuHu';

  @override
  String get homeShopBranch => 'Chi nhánh cửa hàng';

  @override
  String get homeDeselect => 'Bỏ chọn';

  @override
  String get homeSearchHint => 'Tìm bánh mì, đồ uống...';

  @override
  String get homePromoForYou => 'Khuyến mãi dành cho bạn';

  @override
  String get homeExpired => 'Hết hạn';

  @override
  String get homeFlash => 'FLASH';

  @override
  String homeDiscountFormat(Object discount, Object minOrder) {
    return 'Giảm $discount • Đơn từ $minOrder';
  }

  @override
  String homeDiscountPercentFormat(Object discount, Object maxDiscount) {
    return 'Giảm $discount% • Tối đa $maxDiscount';
  }

  @override
  String homeClaimedVoucherSnackbar(Object code) {
    return 'Đã lưu mã \"$code\" vào ví!';
  }

  @override
  String get homeClaimed => 'Đã lưu';

  @override
  String get homeClaimVoucher => 'Lưu mã';

  @override
  String get homeBestSellersBranch => 'Bán chạy tại chi nhánh';

  @override
  String get homeBestSellersGlobal => 'Bán chạy toàn hệ thống';

  @override
  String get homeSalesBranch => 'Đang giảm giá tại chi nhánh';

  @override
  String get homeSalesGlobal => 'Đang giảm giá toàn hệ thống';

  @override
  String get homeAllBranches => 'Tất cả chi nhánh';

  @override
  String get homeCategories => 'Danh mục';

  @override
  String get homeAll => 'Tất cả';

  @override
  String get homeShopMenu => 'Thực đơn của cửa hàng';

  @override
  String get homeAllItems => 'Tất cả món';

  @override
  String get homeNoProductsFound => 'Không tìm thấy món phù hợp';

  @override
  String homeRemainingVouchers(Object count) {
    return 'Còn $count mã';
  }

  @override
  String get homeSoldOutVouchers => 'Hết mã';

  @override
  String get detailTitle => 'Chi tiết sản phẩm';

  @override
  String get detailSelectSize => 'Chọn kích cỡ';

  @override
  String get detailExtraOptions => 'Tùy chọn thêm';

  @override
  String get detailAddToCart => 'Thêm vào giỏ hàng';

  @override
  String get detailDescription => 'Thông tin chi tiết';

  @override
  String detailPrepTime(Object minutes) {
    return '$minutes phút chuẩn bị';
  }

  @override
  String get detailTotalPrice => 'Tổng cộng';

  @override
  String get detailAddedToCart => 'Đã thêm vào giỏ hàng!';

  @override
  String get detailBuyNow => 'Mua ngay';

  @override
  String get detailQuantity => 'Số lượng';

  @override
  String get detailBuyNowSuccess => 'Đang tiến hành đặt hàng mua ngay!';

  @override
  String get detailShopSection => 'Cửa hàng cung cấp';

  @override
  String detailReviewsSection(Object count) {
    return 'Đánh giá từ khách hàng ($count)';
  }

  @override
  String get detailNoReviews => 'Chưa có đánh giá nào cho sản phẩm này';

  @override
  String detailShopPhone(Object phone) {
    return 'Hotline chi nhánh: $phone';
  }

  @override
  String get detailNoRatingYet => 'Chưa có đánh giá';

  @override
  String get detailOtherShopsSection => 'Các chi nhánh khác cùng bán';

  @override
  String get orderStatusPending => 'Chờ xác nhận';

  @override
  String get orderStatusConfirmed => 'Đã xác nhận';

  @override
  String get orderStatusPreparing => 'Đang chuẩn bị';

  @override
  String get orderStatusDelivering => 'Đang giao hàng';

  @override
  String get orderStatusCompleted => 'Đã hoàn thành';

  @override
  String get orderStatusCancelled => 'Đã hủy';

  @override
  String get cancelOrderButton => 'Hủy đơn hàng';

  @override
  String get cancelOrderConfirmTitle => 'Xác nhận hủy đơn';

  @override
  String get cancelOrderConfirmMessage =>
      'Bạn có chắc chắn muốn hủy đơn hàng này không?';

  @override
  String get cancelSuccess => 'Hủy đơn hàng thành công!';

  @override
  String get yes => 'Có';

  @override
  String get no => 'Không';

  @override
  String get orderCodeLabel => 'Mã đơn: ';

  @override
  String get orderDateLabel => 'Ngày đặt: ';

  @override
  String get paymentMethodLabel => 'Phương thức thanh toán';

  @override
  String get paymentStatusLabel => 'Trạng thái thanh toán';

  @override
  String get addressLabel => 'Địa chỉ giao hàng';

  @override
  String get itemsTotalLabel => 'Tiền món';

  @override
  String get deliveryFeeLabel => 'Phí giao hàng';

  @override
  String get discountLabel => 'Giảm giá';

  @override
  String get totalAmountLabel => 'Tổng cộng';

  @override
  String get paymentMethodBank => 'Chuyển khoản';

  @override

  String get paymentStatusUnpaid => 'Chưa thanh toán';

  @override
  String get paymentStatusPaid => 'Đã thanh toán';

  @override
  String get paymentStatusRefunded => 'Đã hoàn tiền';

  @override
  String get profileMyOrders => 'Đơn hàng của tôi';

  @override
  String get profileMyOrdersSub => 'Theo dõi và quản lý đơn hàng';

  @override
  String get profileAddresses => 'Địa chỉ giao hàng';

  @override
  String get profileAddressesSub => 'Quản lý địa chỉ nhận hàng của bạn';

  @override
  String get profileMyVouchers => 'Ví voucher';

  @override
  String get profileMyVouchersSub => 'Xem các mã giảm giá đã lưu';

  @override
  String get profileEditProfile => 'Chỉnh sửa hồ sơ';

  @override
  String get profileEditProfileSub => 'Cập nhật thông tin cá nhân';

  @override
  String get profileChangePassword => 'Đổi mật khẩu';

  @override
  String get profileChangePasswordSub => 'Bảo mật tài khoản của bạn';

  @override
  String get profileSettings => 'Cài đặt';

  @override
  String get profileSettingsSub => 'Thông báo, ngôn ngữ và nhiều hơn nữa';

  @override
  String get profileHelpCenter => 'Trung tâm hỗ trợ';

  @override
  String get profileHelpCenterSub => 'Câu hỏi thường gặp và hỗ trợ khách hàng';

  @override
  String get profileLogoutConfirmTitle => 'Đăng xuất';

  @override
  String get profileLogoutConfirmMessage => 'Bạn có chắc chắn muốn đăng xuất?';

  @override
  String get profileCancel => 'Hủy';

  @override
  String get editProfileTitle => 'Chỉnh sửa hồ sơ';

  @override
  String get editProfilePhoneHint => 'Số điện thoại';

  @override
  String get editProfileChangePhoto => 'Đổi ảnh đại diện';

  @override
  String get editProfileSaveButton => 'Lưu thay đổi';

  @override
  String get editProfileSaveSuccess => 'Cập nhật hồ sơ thành công';

  @override
  String get editProfileSaveError =>
      'Cập nhật hồ sơ thất bại, vui lòng thử lại';

  @override
  String get editProfileAvatarError =>
      'Cập nhật ảnh đại diện thất bại, vui lòng thử lại';

  @override
  String get addressesTitle => 'Địa chỉ giao hàng';

  @override
  String get addressesEmptyTitle => 'Chưa có địa chỉ nào';

  @override
  String get addressesEmptySubtitle => 'Thêm địa chỉ giao hàng để bắt đầu';

  @override
  String get addressAddButton => 'Thêm địa chỉ mới';

  @override
  String get addressDefaultLabel => 'Mặc định';

  @override
  String get addressSetDefaultAction => 'Đặt làm mặc định';

  @override
  String get addressEditAction => 'Sửa';

  @override
  String get addressDeleteAction => 'Xóa';

  @override
  String get addressDeleteConfirmTitle => 'Xóa địa chỉ';

  @override
  String get addressDeleteConfirmMessage =>
      'Bạn có chắc chắn muốn xóa địa chỉ này?';

  @override
  String get addressFormAddTitle => 'Thêm địa chỉ';

  @override
  String get addressFormEditTitle => 'Sửa địa chỉ';

  @override
  String get addressReceiverNameHint => 'Tên người nhận';

  @override
  String get addressReceiverPhoneHint => 'Số điện thoại người nhận';

  @override
  String get addressProvinceHint => 'Tỉnh / Thành phố';

  @override
  String get addressWardHint => 'Phường / Xã';

  @override
  String get addressStreetHint => 'Số nhà, tên đường';

  @override
  String get addressLabelHome => 'Nhà';

  @override
  String get addressLabelCompany => 'Công ty';

  @override
  String get addressLabelOther => 'Khác';

  @override
  String get addressUseCurrentLocation => 'Dùng vị trí hiện tại';

  @override
  String get addressLocationDetecting => 'Đang xác định vị trí...';

  @override
  String get addressLocationServiceDisabled =>
      'Vui lòng bật dịch vụ định vị (GPS)';

  @override
  String get addressLocationPermissionDenied =>
      'Ứng dụng cần quyền truy cập vị trí';

  @override
  String get addressLocationPermissionDeniedForever =>
      'Quyền vị trí đã bị từ chối vĩnh viễn, vui lòng bật trong Cài đặt';

  @override
  String get addressLocationFailed =>
      'Không thể xác định vị trí, vui lòng thử lại';

  @override
  String get addressLocationDetected =>
      'Đã xác định vị trí, vui lòng kiểm tra lại thông tin';

  @override
  String get selectAddressTitle => 'Địa chỉ giao hàng';

  @override
  String get selectAddressSearchHint => 'Tìm vị trí';

  @override
  String get selectAddressSavedTitle => 'Địa chỉ đã lưu';

  @override
  String get selectAddressEmpty => 'Chưa có địa chỉ đã lưu';

  @override
  String get notificationsTitle => 'Thông báo';

  @override
  String get notificationsMarkAllRead => 'Đánh dấu đã đọc tất cả';

  @override
  String get notificationsFilterAll => 'Tất cả';

  @override
  String get notificationsFilterOrder => 'Đơn hàng';

  @override
  String get notificationsFilterPromotion => 'Khuyến mãi';

  @override
  String get notificationsFilterSystem => 'Hệ thống';

  @override
  String get notificationsEmptyTitle => 'Chưa có thông báo';

  @override
  String get notificationsEmptySubtitle => 'Thông báo mới sẽ hiện ở đây';

  @override
  String get notificationsJustNow => 'Vừa xong';

  @override
  String notificationsMinutesAgo(int count) {
    return '$count phút trước';
  }

  @override
  String notificationsHoursAgo(int count) {
    return '$count giờ trước';
  }

  @override
  String notificationsDaysAgo(int count) {
    return '$count ngày trước';
  }

  @override
  String get addressSetDefaultLabel => 'Đặt làm địa chỉ mặc định';

  @override
  String get addressSaveButton => 'Lưu địa chỉ';

  @override
  String get addressSaveError => 'Lưu địa chỉ thất bại, vui lòng thử lại';

  @override
  String get addressDeleteError => 'Xóa địa chỉ thất bại, vui lòng thử lại';

  @override
  String get myVouchersTitle => 'Ví voucher';

  @override
  String get myVouchersEmptyTitle => 'Chưa có voucher nào';

  @override
  String get myVouchersEmptySubtitle =>
      'Lưu voucher từ trang chủ để xem tại đây';

  @override
  String get myVouchersUsedLabel => 'Đã dùng';

  @override
  String get myVouchersExpiredLabel => 'Hết hạn';

  @override
  String get myVouchersAvailableLabel => 'Còn hiệu lực';

  @override
  String get voucherEnterCodeHint => 'Nhập mã voucher';

  @override
  String get voucherRedeemSuccess => 'Áp dụng mã voucher thành công';

  @override
  String get voucherDiscountLabel => 'GIẢM GIÁ';

  @override
  String get voucherFreeShipLabel => 'MIỄN PHÍ\nVẬN CHUYỂN';

  @override
  String voucherMinOrder(String amount) {
    return 'Đơn tối thiểu $amount';
  }

  @override
  String get voucherUseNowButton => 'Dùng ngay';

  @override
  String get voucherUseAtCheckoutMsg =>
      'Voucher này sẽ được áp dụng khi thanh toán';

  @override
  String get voucherAvailableSection => 'Voucher đang có';

  @override
  String get voucherSaveButton => 'Lưu';

  @override
  String myVouchersExpiresOn(String date) {
    return 'Hết hạn ngày $date';
  }

  @override
  String get changePasswordNotApplicable =>
      'Đổi mật khẩu không áp dụng cho tài khoản đăng nhập bằng Google/Facebook';

  @override
  String get changePasswordCurrentHint => 'Mật khẩu hiện tại';

  @override
  String get changePasswordNewHint => 'Mật khẩu mới';

  @override
  String get changePasswordConfirmHint => 'Xác nhận mật khẩu mới';

  @override
  String get changePasswordSaveButton => 'Cập nhật mật khẩu';

  @override
  String get changePasswordSuccess => 'Đổi mật khẩu thành công';

  @override
  String get changePasswordWrongCurrent => 'Mật khẩu hiện tại không đúng';

  @override
  String get changePasswordWeak => 'Mật khẩu mới quá yếu';

  @override
  String get changePasswordDefaultError =>
      'Đổi mật khẩu thất bại, vui lòng thử lại';

  @override
  String get settingsLanguageSection => 'Ngôn ngữ';

  @override
  String get settingsLanguageVietnamese => 'Tiếng Việt';

  @override
  String get settingsLanguageEnglish => 'Tiếng Anh';

  @override
  String get helpCenterFaqSection => 'Câu hỏi thường gặp';

  @override
  String get helpCenterContactSection => 'Liên hệ hỗ trợ';

  @override
  String get helpCenterFaq1Question => 'Làm sao để đặt hàng?';

  @override
  String get helpCenterFaq1Answer =>
      'Chọn món trong thực đơn của cửa hàng, thêm vào giỏ hàng, chọn địa chỉ giao hàng và phương thức thanh toán, rồi xác nhận đặt hàng.';

  @override
  String get helpCenterFaq2Question => 'Làm sao để theo dõi đơn hàng?';

  @override
  String get helpCenterFaq2Answer =>
      'Vào tab Lịch sử để xem trạng thái đơn hàng hiện tại và các đơn hàng trước đó.';

  @override
  String get helpCenterFaq3Question => 'Làm sao để dùng voucher?';

  @override
  String get helpCenterFaq3Answer =>
      'Lưu voucher từ trang chủ hoặc màn Ví voucher, sau đó chọn voucher đó khi thanh toán để được giảm giá.';

  @override
  String get helpCenterFaq4Question => 'Làm sao để đổi địa chỉ giao hàng?';

  @override
  String get helpCenterFaq4Answer =>
      'Vào Cá nhân > Địa chỉ giao hàng để thêm, sửa hoặc đặt địa chỉ mặc định.';

  @override
  String get helpCenterCallSupport => 'Gọi hỗ trợ';

  @override
  String get helpCenterEmailSupport => 'Email hỗ trợ';
}
