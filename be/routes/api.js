var express = require("express");
var router = express.Router();
var accCtrl = require("../controllers/account.controller");
var catCtrl = require("../controllers/category.controller");
var prodCtrl = require("../controllers/product.controller");
var voucherCtrl = require("../controllers/voucher.controller");
var shopCtrl = require("../controllers/shop.controller");
var addressCtrl = require("../controllers/address.controller");

router.post("/auth/firebase", accCtrl.verifyFirebaseUser);

// Shop Routes
router.get("/shops", shopCtrl.getShops);

// Category Routes
router.get("/categories", catCtrl.getGlobalCategories);
router.get("/shops/:shopId/categories", catCtrl.getShopCategories);

// Product Routes
router.get("/products/best-sellers", prodCtrl.getBestSellers);
router.get("/products/sales", prodCtrl.getSaleProducts);
router.get("/products", prodCtrl.getProducts);
router.get("/products/:id", prodCtrl.getProductDetail);

const { firebaseAuth, optionalAuth } = require("../middlewares/auth.middlewares");
const { uploadAvatar } = require("../middlewares/upload.middlewares");

// Voucher Routes
router.get("/vouchers", optionalAuth, voucherCtrl.getVouchers);
router.get("/vouchers/saved", firebaseAuth, voucherCtrl.getSavedVouchers);
router.post("/vouchers/redeem", firebaseAuth, voucherCtrl.redeemVoucherByCode);
router.post("/vouchers/:id/save", firebaseAuth, voucherCtrl.saveVoucher);

// Account Routes
router.put("/account/profile", firebaseAuth, accCtrl.updateProfile);
router.post(
  "/account/avatar",
  firebaseAuth,
  uploadAvatar.single("avatar"),
  accCtrl.uploadAvatar,
);

// Address Routes
router.get("/addresses", firebaseAuth, addressCtrl.getMyAddresses);
router.post("/addresses", firebaseAuth, addressCtrl.createAddress);
router.put("/addresses/:id", firebaseAuth, addressCtrl.updateAddress);
router.delete("/addresses/:id", firebaseAuth, addressCtrl.deleteAddress);

module.exports = router;
