var express = require("express");
var router = express.Router();
var accCtrl = require("../controllers/account.controller");
var catCtrl = require("../controllers/category.controller");
var prodCtrl = require("../controllers/product.controller");
var voucherCtrl = require("../controllers/voucher.controller");
var shopCtrl = require("../controllers/shop.controller");
var addressCtrl = require("../controllers/address.controller");
var orderCtrl = require("../controllers/order.controller");
var bannerCtrl = require("../controllers/banner.controller");
var notificationCtrl = require("../controllers/notification.controller");

router.post("/auth/firebase", accCtrl.verifyFirebaseUser);

// Banner Routes
router.get("/banners", bannerCtrl.getActiveBanners);

// Shop Routes
router.get("/shops", shopCtrl.getShops);

// Category Routes
router.get("/categories", catCtrl.getGlobalCategories);

// Product Routes
router.get("/products/best-sellers", prodCtrl.getBestSellers);
router.get("/products/sales", prodCtrl.getSaleProducts);
router.get("/products/featured", prodCtrl.getFeaturedProducts);
router.get("/products/:id", prodCtrl.getProductDetail);
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

// Order Routes
router.post("/orders", firebaseAuth, orderCtrl.createOrder);
router.get("/orders", firebaseAuth, orderCtrl.getOrders);
router.get("/orders/:id", firebaseAuth, orderCtrl.getOrderById);
router.put("/orders/:id/cancel", firebaseAuth, orderCtrl.cancelOrder);
router.post("/orders/:id/review", firebaseAuth, orderCtrl.createReview);
router.get("/delivery-fee/preview", firebaseAuth, orderCtrl.previewDeliveryFee);

// Notification Routes
router.get("/notifications", firebaseAuth, notificationCtrl.getMyNotifications);
router.get("/notifications/unread-count", firebaseAuth, notificationCtrl.getUnreadCount);
router.put("/notifications/read-all", firebaseAuth, notificationCtrl.markAllAsRead);
router.put("/notifications/:id/read", firebaseAuth, notificationCtrl.markAsRead);
router.delete("/notifications", firebaseAuth, notificationCtrl.deleteAllNotifications);
router.delete("/notifications/:id", firebaseAuth, notificationCtrl.deleteNotification);

// Device (FCM) Routes
router.post("/devices/register", firebaseAuth, notificationCtrl.registerDevice);
router.post("/devices/unregister", firebaseAuth, notificationCtrl.unregisterDevice);

// Cart Routes
var cartCtrl = require("../controllers/cart.controller");
router.get("/carts", firebaseAuth, cartCtrl.getCart);
router.delete("/carts", firebaseAuth, cartCtrl.clearCart);
router.post("/carts/items", firebaseAuth, cartCtrl.addToCart);
router.put("/carts/items/:itemId", firebaseAuth, cartCtrl.updateCartItem);
router.delete("/carts/items/:itemId", firebaseAuth, cartCtrl.deleteCartItem);
router.post("/carts/switch-shop-options", firebaseAuth, cartCtrl.getSwitchShopOptions);
router.post("/carts/switch-shop", firebaseAuth, cartCtrl.switchShop);

// Payment Routes
var paymentCtrl = require("../controllers/payment.controller");
router.post("/payments/vnpay", firebaseAuth, paymentCtrl.createVnpayPayment);
router.get("/payment/vnpay-return", paymentCtrl.vnpayReturn);
router.get("/payment/vnpay-ipn", paymentCtrl.vnpayIpn);
router.get("/payment/vnpay-verify", firebaseAuth, paymentCtrl.verifyPayment);
// Notification Routes
const notificationRouter = require("./notification.routes");
router.use("/notifications", notificationRouter);

module.exports = router;
