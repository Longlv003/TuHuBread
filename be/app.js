var express = require("express");
var path = require("path");
var cookieParser = require("cookie-parser");
var logger = require("morgan");
var helmet = require("helmet");

var indexRouter = require("./routes/index");
var usersRouter = require("./routes/users");
var apiRouter = require("./routes/api");
var shopRouter = require("./routes/shop_web");
var adminRouter = require("./routes/admin_web");

var app = express();

// View engine setup
app.set("views", path.join(__dirname, "views"));
app.set("view engine", "ejs");

app.use(logger("dev"));
// CSP tắt vì các view EJS admin/shop dùng inline <script> + CDN font/icon bên
// ngoài (Google Fonts, FontAwesome) — bật CSP mặc định của helmet sẽ chặn hết.
// Các header bảo mật khác (X-Content-Type-Options, X-Frame-Options, HSTS...)
// vẫn được giữ nguyên.
app.use(helmet({ contentSecurityPolicy: false }));
app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(cookieParser());
app.use(express.static(path.join(__dirname, "public")));

app.use("/", indexRouter);
app.use("/users", usersRouter);
app.use("/api", apiRouter);
app.use("/shop", shopRouter);
app.use("/admin", adminRouter);

// 404 — không khớp route nào ở trên
app.use((req, res) => {
  if (req.path.startsWith("/api")) {
    return res.status(404).json({ msg: "Not found", data: null });
  }
  res.status(404).render("error", { message: "Không tìm thấy trang yêu cầu." });
});

// Middleware xử lý lỗi toàn cục — bắt buộc phải có 4 tham số (err, req, res, next)
// để Express nhận diện đây là error-handling middleware. Đây là lưới an toàn
// cuối cùng: Express 4 KHÔNG tự bắt promise rejection từ route handler, nên nếu
// 1 middleware/controller nào đó quên try/catch, request sẽ rơi vào đây thay vì
// treo mãi hoặc làm crash tiến trình.
app.use((err, req, res, next) => {
  console.error("[Unhandled error]", err);
  if (res.headersSent) {
    return next(err);
  }
  if (req.path.startsWith("/api")) {
    return res.status(500).json({ msg: "Server error", data: null });
  }
  res.status(500).render("error", { message: "Đã có lỗi xảy ra, vui lòng thử lại sau." });
});

module.exports = app;
