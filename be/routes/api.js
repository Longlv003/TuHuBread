var express = require("express");
var router = express.Router();
var accCtrl = require("../controllers/account.controller");
var catCtrl = require("../controllers/category.controller");
var prodCtrl = require("../controllers/product.controller");
var voucherCtrl = require("../controllers/voucher.controller");
var shopCtrl = require("../controllers/shop.controller");
const fs = require("fs");
const path = require("path");
const multer = require("multer");

// Đảm bảo thư mục upload tồn tại
const avatarDir = path.join(__dirname, "../public/images/avatars");
if (!fs.existsSync(avatarDir)) {
  fs.mkdirSync(avatarDir, { recursive: true });
}

// Cấu hình Multer lưu ảnh
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, avatarDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
    cb(null, "avatar-" + uniqueSuffix + path.extname(file.originalname));
  },
});

const upload = multer({
  storage: storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // Giới hạn 5MB
  fileFilter: (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|webp/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype);
    if (extname && mimetype) {
      return cb(null, true);
    }
    cb(new Error("Chỉ hỗ trợ upload file ảnh (jpeg, jpg, png, webp)!"));
  },
});

router.post("/auth/firebase", accCtrl.verifyFirebaseUser);

const { firebaseAuth, optionalAuth } = require("../middlewares/auth.middlewares");

router.put("/users/profile", firebaseAuth, accCtrl.updateProfile);
router.post("/users/profile/avatar", firebaseAuth, upload.single("avatar"), accCtrl.uploadAvatar);


// Shop Routes
router.get("/shops", shopCtrl.getShops);

// Category Routes
router.get("/categories", catCtrl.getGlobalCategories);
router.get("/shops/:shopId/categories", catCtrl.getShopCategories);

// Product Routes
router.get("/products/best-sellers", prodCtrl.getBestSellers);
router.get("/products/sales", prodCtrl.getSaleProducts);
router.get("/products", prodCtrl.getProducts);



// Voucher Routes
router.get("/vouchers", optionalAuth, voucherCtrl.getVouchers);
router.post("/vouchers/:id/save", firebaseAuth, voucherCtrl.saveVoucher);

module.exports = router;
