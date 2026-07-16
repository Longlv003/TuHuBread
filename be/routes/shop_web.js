const express = require("express");
const router = express.Router();
const shopAuthController = require("../controllers/shop_web/shop_auth.controller");
const shopDashboardController = require("../controllers/shop_web/shop_dashboard.controller");
const { authMiddleware, guestMiddleware } = require("../middlewares/shop_auth.middlewares");

const upload = require("../middlewares/upload.middleware");
const uploadCategory = require("../middlewares/upload_category.middleware");
const shopCategoryController = require("../controllers/shop_web/shop_category.controller");

// Guest pages (Login & Register)
router.get("/login", guestMiddleware, shopAuthController.showLogin);
router.get("/register", guestMiddleware, shopAuthController.showRegister);
router.post("/login", guestMiddleware, shopAuthController.login);
router.post("/register", guestMiddleware, shopAuthController.register);

// Authenticated pages (Dashboard, Logo & Logout)
router.get("/dashboard", authMiddleware, shopDashboardController.showDashboard);
router.post("/update-logo", authMiddleware, upload.single("logo"), shopAuthController.updateLogo);
router.get("/logout", authMiddleware, shopAuthController.logout);

// Shop Categories CRUD routes
router.get("/categories", authMiddleware, shopCategoryController.showCategories);
router.post("/categories/add", authMiddleware, uploadCategory.single("categoryIcon"), shopCategoryController.addCategory);
router.post("/categories/edit/:id", authMiddleware, uploadCategory.single("categoryIcon"), shopCategoryController.editCategory);
router.post("/categories/delete/:id", authMiddleware, shopCategoryController.deleteCategory);

module.exports = router;
