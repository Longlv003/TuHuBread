import 'package:intl/intl.dart';

class CurrencyFormatter {
  // Bộ định dạng số phân cách hàng nghìn bằng dấu chấm (đặc trưng tiền tệ VNĐ)
  static final NumberFormat _vietnameseFormat = NumberFormat('#,###', 'vi_VN');

  /// Định dạng số tiền sang dạng chuỗi kèm ký tự 'đ' (Ví dụ: 18000 -> "18.000đ")
  static String formatVND(double amount) {
    try {
      final formatted = _vietnameseFormat.format(amount.toInt());
      return '$formattedđ';
    } catch (e) {
      return '${amount.toInt()}đ';
    }
  }

  /// Định dạng số tiền sang dạng chuỗi chỉ có số và dấu phân cách (Ví dụ: 18000 -> "18.000")
  static String formatNumber(double amount) {
    try {
      return _vietnameseFormat.format(amount.toInt());
    } catch (e) {
      return amount.toInt().toString();
    }
  }
}
