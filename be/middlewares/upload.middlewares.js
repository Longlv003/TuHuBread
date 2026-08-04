const path = require("path");
const multer = require("multer");
const { imageFileFilter, safeImageExtension } = require("../utils/imageUpload.util");

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, path.join(__dirname, "..", "public", "images", "avatars"));
  },
  filename: (req, file, cb) => {
    const uid = req.user?.uid || "unknown";
    const ext = safeImageExtension(file.originalname);
    cb(null, `${uid}_${Date.now()}${ext}`);
  },
});

const uploadAvatar = multer({
  storage,
  fileFilter: imageFileFilter,
  limits: { fileSize: 5 * 1024 * 1024 },
});

module.exports = { uploadAvatar };
