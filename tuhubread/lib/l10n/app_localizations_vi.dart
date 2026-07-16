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

  @override
  String get loginCancelledError => 'Đã hủy đăng nhập';

  @override
  String get firebaseErrorAccountExistsWithDifferentCredential =>
      'Email này đã được sử dụng với một phương thức đăng nhập khác (ví dụ: Google hoặc Mật khẩu)';

  @override
  String get tabHome => 'Trang chủ';

  @override
  String get tabCart => 'Giỏ hàng';

  @override
  String get tabHistory => 'Lịch sử';

  @override
  String get tabProfile => 'Cá nhân';

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
  String get paymentMethodCash => 'Tiền mặt';

  @override
  String get paymentMethodMomo => 'Ví MoMo';

  @override
  String get paymentMethodBank => 'Chuyển khoản';

  @override
  String get paymentMethodVnpay => 'VNPAY';

  @override
  String get paymentStatusUnpaid => 'Chưa thanh toán';

  @override
  String get paymentStatusPaid => 'Đã thanh toán';

  @override
  String get paymentStatusRefunded => 'Đã hoàn tiền';
}
