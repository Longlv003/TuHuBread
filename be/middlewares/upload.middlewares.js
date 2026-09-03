const path = require("path");
const fs = require("fs");
const multer = require("multer");
const { imageFileFilter, safeImageExtension } = require("../utils/imageUpload.util");

const uploadDir = path.join(__dirname, "..", "public", "images", "avatars");
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uid = req.user?.uid || "unknown";
    const ext = safeImageExtension(file.originalname, file.mimetype);
    cb(null, `${uid}_${Date.now()}${ext}`);
  },
});

const uploadAvatar = multer({
  storage,
  fileFilter: imageFileFilter,
  limits: { fileSize: 5 * 1024 * 1024 },
});

module.exports = { uploadAvatar };
