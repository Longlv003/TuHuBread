var express = require("express");
var router = express.Router();
var accCtrl = require("../controllers/account.controller");
var catCtrl = require("../controllers/category.controller");
var prodCtrl = require("../controllers/product.controller");
var voucherCtrl = require("../controllers/voucher.controller");
var shopCtrl = require("../controllers/shop.controller");

router.post("/auth/firebase", accCtrl.verifyFirebaseUser);

// Shop Routes
router.get("/shops", shopCtrl.getShops);

// Category Routes
router.get("/categories", catCtrl.getGlobalCategories);
router.get("/shops/:shopId/categories", catCtrl.getShopCategories);

// Product Routes
router.get("/products/best-sellers", prodCtrl.getBestSellers);
router.get("/products/sales", prodCtrl.getSaleProducts);
router.get("/products/:id", prodCtrl.getProductDetail);
router.get("/products", prodCtrl.getProducts);

const { firebaseAuth, optionalAuth } = require("../middlewares/auth.middlewares");

// Voucher Routes
router.get("/vouchers", optionalAuth, voucherCtrl.getVouchers);
router.post("/vouchers/:id/save", firebaseAuth, voucherCtrl.saveVoucher);

module.exports = router;
