const express = require("express");
const router = express.Router();
const adminAuthController = require("../controllers/admin/admin_auth.controller");
const adminUserController = require("../controllers/admin/admin_user.controller");
const adminBannerController = require("../controllers/admin/admin_banner.controller");
const adminNotificationController = require("../controllers/admin/admin_notification.controller");
const adminCategoryController = require("../controllers/admin/admin_category.controller");
const adminVoucherController = require("../controllers/admin/admin_voucher.controller");
const adminDashboardController = require("../controllers/admin/admin_dashboard.controller");
const adminShopController = require("../controllers/admin/admin_shop.controller");
const { adminAuthMiddleware, adminGuestMiddleware } = require("../middlewares/admin_auth.middlewares");
const uploadBanner = require("../middlewares/upload_banner.middleware");
const uploadCategory = require("../middlewares/upload_category.middleware");

// Guest pages (Login)
router.get("/login", adminGuestMiddleware, adminAuthController.showLogin);
router.post("/login", adminGuestMiddleware, adminAuthController.login);
router.get("/logout", adminAuthMiddleware, adminAuthController.logout);

// User management routes
router.get("/users", adminAuthMiddleware, adminUserController.showUsers);
router.post("/users/edit/:id", adminAuthMiddleware, adminUserController.updateUser);
router.post("/users/toggle-lock/:id", adminAuthMiddleware, adminUserController.toggleLock);

// Banner management routes
router.get("/banners", adminAuthMiddleware, adminBannerController.showBanners);
router.post("/banners/add", adminAuthMiddleware, uploadBanner.single("image"), adminBannerController.addBanner);
router.post("/banners/edit/:id", adminAuthMiddleware, uploadBanner.single("image"), adminBannerController.editBanner);
router.post("/banners/delete/:id", adminAuthMiddleware, adminBannerController.deleteBanner);

// Notification management routes
router.get("/notifications", adminAuthMiddleware, adminNotificationController.showNotifications);
router.post("/notifications/add", adminAuthMiddleware, adminNotificationController.createNotification);

// Global category management routes
router.get("/categories", adminAuthMiddleware, adminCategoryController.showCategories);
router.post("/categories/add", adminAuthMiddleware, uploadCategory.single("categoryIcon"), adminCategoryController.addCategory);
router.post("/categories/edit/:id", adminAuthMiddleware, uploadCategory.single("categoryIcon"), adminCategoryController.editCategory);
router.post("/categories/delete/:id", adminAuthMiddleware, adminCategoryController.deleteCategory);

// Platform voucher management routes
router.get("/vouchers", adminAuthMiddleware, adminVoucherController.showVouchers);
router.post("/vouchers/add", adminAuthMiddleware, adminVoucherController.addVoucher);
router.post("/vouchers/edit/:id", adminAuthMiddleware, adminVoucherController.editVoucher);
router.post("/vouchers/delete/:id", adminAuthMiddleware, adminVoucherController.deleteVoucher);

// Dashboard route
router.get("/dashboard", adminAuthMiddleware, adminDashboardController.showDashboard);

// Shop (branch) management routes
router.get("/shops", adminAuthMiddleware, adminShopController.showShops);
router.post("/shops/add", adminAuthMiddleware, adminShopController.addShop);
router.post("/shops/edit/:id", adminAuthMiddleware, adminShopController.editShop);

module.exports = router;
