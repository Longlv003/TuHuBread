var express = require("express");
var router = express.Router();
var accCtrl = require("../controllers/account.controller");
var catCtrl = require("../controllers/category.controller");
var prodCtrl = require("../controllers/product.controller");
var voucherCtrl = require("../controllers/voucher.controller");
var shopCtrl = require("../controllers/shop.controller");
var orderCtrl = require("../controllers/order.controller");

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

const { firebaseAuth, optionalAuth } = require("../middlewares/auth.middlewares");

// Voucher Routes
router.get("/vouchers", optionalAuth, voucherCtrl.getVouchers);
router.post("/vouchers/:id/save", firebaseAuth, voucherCtrl.saveVoucher);

// Order Routes
router.get("/orders", firebaseAuth, orderCtrl.getOrders);
router.get("/orders/:id", firebaseAuth, orderCtrl.getOrderById);
router.put("/orders/:id/cancel", firebaseAuth, orderCtrl.cancelOrder);

module.exports = router;
