const multer = require("multer");
const path = require("path");
const fs = require("fs");
const { imageFileFilter, safeImageExtension } = require("../utils/imageUpload.util");

const uploadDir = path.join(__dirname, "../public/images/categories");
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
    cb(null, `cat_${uniqueSuffix}${ext}`);
  }
});

const uploadCategory = multer({
  storage: storage,
  fileFilter: imageFileFilter,
  limits: {
    fileSize: 3 * 1024 * 1024 // 3 MB max
  }
});

module.exports = uploadCategory;
