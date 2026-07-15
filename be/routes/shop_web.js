const express = require("express");
const router = express.Router();
const shopAuthController = require("../controllers/shop_web/shop_auth.controller");
const shopDashboardController = require("../controllers/shop_web/shop_dashboard.controller");
const { authMiddleware, guestMiddleware } = require("../middlewares/shop_auth.middlewares");

const upload = require("../middlewares/upload.middleware");

// Guest pages (Login & Register)
router.get("/login", guestMiddleware, shopAuthController.showLogin);
router.get("/register", guestMiddleware, shopAuthController.showRegister);
router.post("/login", guestMiddleware, shopAuthController.login);
router.post("/register", guestMiddleware, shopAuthController.register);

// Authenticated pages (Dashboard & Logout)
router.get("/dashboard", authMiddleware, shopDashboardController.showDashboard);
router.post("/update-logo", authMiddleware, upload.single("logo"), shopAuthController.updateLogo);
router.get("/logout", authMiddleware, shopAuthController.logout);

module.exports = router;
