const rateLimit = require("express-rate-limit");

// Giới hạn brute-force trên các trang đăng nhập/đăng ký admin & shop —
// trước đây không có giới hạn nào, cho phép thử mật khẩu không giới hạn số lần.
const authRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 phút
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: { msg: "Quá nhiều lần thử, vui lòng thử lại sau ít phút.", data: null },
});

module.exports = { authRateLimiter };
