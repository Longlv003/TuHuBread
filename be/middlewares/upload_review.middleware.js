const multer = require("multer");
const path = require("path");
const fs = require("fs");
const { imageFileFilter, safeImageExtension } = require("../utils/imageUpload.util");

const uploadDir = path.join(__dirname, "../public/images/reviews");
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, uploadDir);
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
    const ext = safeImageExtension(file.originalname);
    cb(null, `review_${uniqueSuffix}${ext}`);
  }
});

const uploadReview = multer({
  storage: storage,
  fileFilter: imageFileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5 MB / ảnh
    files: 5, // tối đa 5 ảnh mỗi đánh giá
  }
});

module.exports = uploadReview;
