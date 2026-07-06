/// Sealed Result type — dùng chung cho toàn bộ repository layer.
///
/// Mỗi repository method trả về `Result<T>` thay vì throw exception.
/// Cubit/UI pattern-match trên `Success` / `Failure` để xử lý từng trường hợp.
sealed class Result<T> {
  const Result();
}

/// Gọi API thành công — chứa data parse được
class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

/// Gọi API thất bại — chứa thông báo lỗi có thể hiển thị
class Failure<T> extends Result<T> {
  final String message;
  const Failure(this.message);
}

/// Extension helpers để dùng gọn hơn trong cubit
extension ResultX<T> on Result<T> {
  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get dataOrNull => switch (this) {
        Success<T> s => s.data,
        Failure<T> _ => null,
      };

  String? get errorOrNull => switch (this) {
        Success<T> _ => null,
        Failure<T> f => f.message,
      };

  /// Trả về data nếu success, ngược lại trả về [fallback]
  T getOrElse(T fallback) => switch (this) {
        Success<T> s => s.data,
        Failure<T> _ => fallback,
      };
}
