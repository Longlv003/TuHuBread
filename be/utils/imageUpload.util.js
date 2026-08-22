const path = require("path");

// Whitelist cố định — không dựa vào mimetype do client tự khai báo (dễ giả mạo),
// cũng không dùng nguyên phần mở rộng gốc của client. Chặn .svg/.html vì chúng có
// thể chứa <script> và bị serve same-origin qua express.static, dẫn tới stored XSS.
const ALLOWED_EXTENSIONS = new Set([".jpg", ".jpeg", ".png", ".webp", ".gif"]);

const EXTENSION_BY_MIMETYPE = {
  "image/jpeg": ".jpg",
  "image/jpg": ".jpg",
  "image/png": ".png",
  "image/webp": ".webp",
  "image/gif": ".gif",
};

// Mimetype "không rõ" — client không khai báo được loại file. Rất phổ biến:
// Dio (app Flutter) mặc định gửi application/octet-stream cho mọi file nếu
// không truyền contentType, dù đó là ảnh JPEG hợp lệ.
const UNKNOWN_MIMETYPES = new Set(["", "application/octet-stream", "binary/octet-stream"]);

/**
 * fileFilter dùng chung cho multer.
 *
 * Nhận diện ảnh qua đuôi file HOẶC mimetype — chỉ cần một trong hai xác định
 * được là ảnh hợp lệ. Trước đây bắt buộc CẢ HAI phải khớp nhau, dẫn tới chặn
 * nhầm ảnh thật trong 2 tình huống rất hay gặp ở app mobile:
 *   - Đuôi .jpg nhưng mimetype là application/octet-stream (Dio mặc định).
 *   - Tên file do image_picker trả về không có đuôi.
 *
 * Việc siết mimetype cũng gần như không tăng bảo mật, vì mimetype do client
 * tự khai nên kẻ tấn công đặt "image/jpeg" là qua được. Lớp bảo vệ thật nằm ở
 * whitelist đuôi file + [safeImageExtension] khi lưu xuống đĩa.
 */
function imageFileFilter(req, file, cb) {
  const ext = path.extname(file.originalname || "").toLowerCase();
  const mimetype = (file.mimetype || "").toLowerCase();

  const extAllowed = ALLOWED_EXTENSIONS.has(ext);
  const mimeAllowed = Object.prototype.hasOwnProperty.call(EXTENSION_BY_MIMETYPE, mimetype);
  const mimeUnknown = UNKNOWN_MIMETYPES.has(mimetype);

  // Không có dấu hiệu nào cho thấy đây là ảnh -> từ chối.
  if (!extAllowed && !mimeAllowed) {
    return cb(
      new ImageValidationError("Chỉ cho phép tải lên file ảnh (jpg, jpeg, png, webp, gif)"),
      false,
    );
  }

  // Đuôi hợp lệ nhưng mimetype lại khai rõ ràng là thứ KHÁC ảnh (vd. .jpg mà
  // khai text/html) -> mâu thuẫn thật sự, từ chối.
  if (extAllowed && !mimeAllowed && !mimeUnknown) {
    return cb(new ImageValidationError("Định dạng file không khớp với đuôi file"), false);
  }

  cb(null, true);
}

/**
 * Lỗi từ chối ảnh của [imageFileFilter] — đánh dấu riêng để middleware xử lý
 * lỗi toàn cục (app.js) nhận diện được đây là lỗi validate hợp lệ (trả thẳng
 * message cho client), khác với lỗi hệ thống bất ngờ (che thành "Server error").
 */
class ImageValidationError extends Error {}

/**
 * Trả về đuôi file an toàn để dùng khi lưu file — luôn nằm trong whitelist,
 * không bao giờ trả thẳng phần mở rộng gốc client gửi lên.
 *
 * Nếu tên gốc không có đuôi hợp lệ thì suy ra từ mimetype (vd. image_picker
 * trả về tên không đuôi kèm mimetype image/png -> lưu thành .png), tránh lưu
 * nhầm ảnh PNG thành .jpg.
 */
function safeImageExtension(originalname, mimetype) {
  const ext = path.extname(originalname || "").toLowerCase();
  if (ALLOWED_EXTENSIONS.has(ext)) return ext;
  return EXTENSION_BY_MIMETYPE[(mimetype || "").toLowerCase()] || ".jpg";
}

module.exports = { imageFileFilter, safeImageExtension, ALLOWED_EXTENSIONS, ImageValidationError };
