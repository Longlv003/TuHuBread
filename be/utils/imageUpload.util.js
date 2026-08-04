const path = require("path");

// Whitelist cố định — không dựa vào mimetype do client tự khai báo (dễ giả mạo),
// cũng không dùng nguyên phần mở rộng gốc của client. Chặn .svg/.html vì chúng có
// thể chứa <script> và bị serve same-origin qua express.static, dẫn tới stored XSS.
const ALLOWED_EXTENSIONS = new Set([".jpg", ".jpeg", ".png", ".webp", ".gif"]);

const ALLOWED_MIMETYPES_BY_EXT = {
  ".jpg": ["image/jpeg"],
  ".jpeg": ["image/jpeg"],
  ".png": ["image/png"],
  ".webp": ["image/webp"],
  ".gif": ["image/gif"],
};

/**
 * fileFilter dùng chung cho multer — chỉ chấp nhận ảnh nằm trong whitelist đuôi
 * file CỐ ĐỊNH, đồng thời đối chiếu với mimetype tương ứng thay vì tin tưởng
 * hoàn toàn mimetype client gửi lên.
 */
function imageFileFilter(req, file, cb) {
  const ext = path.extname(file.originalname || "").toLowerCase();
  if (!ALLOWED_EXTENSIONS.has(ext)) {
    return cb(new Error("Chỉ cho phép tải lên file ảnh (jpg, jpeg, png, webp, gif)"), false);
  }
  const allowedMimes = ALLOWED_MIMETYPES_BY_EXT[ext] || [];
  if (!allowedMimes.includes(file.mimetype)) {
    return cb(new Error("Định dạng file không khớp với đuôi file"), false);
  }
  cb(null, true);
}

/**
 * Trả về đuôi file an toàn để dùng khi lưu file — luôn nằm trong whitelist,
 * không bao giờ trả thẳng phần mở rộng gốc client gửi lên.
 */
function safeImageExtension(originalname) {
  const ext = path.extname(originalname || "").toLowerCase();
  return ALLOWED_EXTENSIONS.has(ext) ? ext : ".jpg";
}

module.exports = { imageFileFilter, safeImageExtension, ALLOWED_EXTENSIONS };
