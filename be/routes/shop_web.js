const express = require("express");
const router = express.Router();
const shopAuthController = require("../controllers/shop_web/shop_auth.controller");
const shopDashboardController = require("../controllers/shop_web/shop_dashboard.controller");
const { authMiddleware, guestMiddleware } = require("../middlewares/shop_auth.middlewares");

const upload = require("../middlewares/upload.middleware");
const uploadCategory = require("../middlewares/upload_category.middleware");
const shopCategoryController = require("../controllers/shop_web/shop_category.controller");
const shopOrderController = require("../controllers/shop_web/shop_order.controller");
const shopProductController = require("../controllers/shop_web/shop_product.controller");
const shopProductVariantController = require("../controllers/shop_web/shop_product_variant.controller");
const shopProductOptionController = require("../controllers/shop_web/shop_product_option.controller");
const shopProductAttributeController = require("../controllers/shop_web/shop_product_attribute.controller");
const shopProductBatchController = require("../controllers/shop_web/shop_product_batch.controller");
const shopSaleController = require("../controllers/shop_web/shop_sale.controller");
const shopVoucherController = require("../controllers/shop_web/shop_voucher.controller");
const shopReviewController = require("../controllers/shop_web/shop_review.controller");
const shopSettingsController = require("../controllers/shop_web/shop_settings.controller");
const shopReportController = require("../controllers/shop_web/shop_report.controller");
const uploadProduct = require("../middlewares/upload_product.middleware");
const uploadShopBanner = require("../middlewares/upload_shop_banner.middleware");

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

// Order management routes
router.get("/orders", authMiddleware, shopOrderController.showOrders);
router.get("/orders/:id", authMiddleware, shopOrderController.showOrderDetail);
router.post("/orders/edit-status/:id", authMiddleware, shopOrderController.updateStatus);

// Product management routes
router.get("/products", authMiddleware, shopProductController.showProducts);
router.get("/products/:id", authMiddleware, shopProductController.showProductDetail);
router.post("/products/add", authMiddleware, uploadProduct.single("variantImage"), shopProductController.addProduct);
router.post("/products/edit/:id", authMiddleware, shopProductController.editProduct);
router.post("/products/delete/:id", authMiddleware, shopProductController.deleteProduct);

router.post("/products/:productId/variants/add", authMiddleware, uploadProduct.single("variantImage"), shopProductVariantController.addVariant);
router.post("/products/:productId/variants/edit/:id", authMiddleware, uploadProduct.single("variantImage"), shopProductVariantController.editVariant);
router.post("/products/:productId/variants/delete/:id", authMiddleware, shopProductVariantController.deleteVariant);

router.post("/products/:productId/options/add", authMiddleware, shopProductOptionController.addOption);
router.post("/products/:productId/options/edit/:id", authMiddleware, shopProductOptionController.editOption);
router.post("/products/:productId/options/delete/:id", authMiddleware, shopProductOptionController.deleteOption);

router.post("/products/:productId/attributes/add", authMiddleware, shopProductAttributeController.addAttribute);
router.post("/products/:productId/attributes/edit/:id", authMiddleware, shopProductAttributeController.editAttribute);
router.post("/products/:productId/attributes/delete/:id", authMiddleware, shopProductAttributeController.deleteAttribute);

router.post("/products/:productId/batches/add", authMiddleware, shopProductBatchController.addBatch);
router.post("/products/:productId/batches/edit/:id", authMiddleware, shopProductBatchController.editBatch);
router.post("/products/:productId/batches/delete/:id", authMiddleware, shopProductBatchController.deleteBatch);

// Promotions / Sales routes
router.get("/sales", authMiddleware, shopSaleController.showSales);
router.post("/sales/add", authMiddleware, shopSaleController.addSale);
router.post("/sales/edit/:id", authMiddleware, shopSaleController.editSale);
router.post("/sales/delete/:id", authMiddleware, shopSaleController.deleteSale);

// Voucher routes
router.get("/vouchers", authMiddleware, shopVoucherController.showVouchers);
router.post("/vouchers/add", authMiddleware, shopVoucherController.addVoucher);
router.post("/vouchers/edit/:id", authMiddleware, shopVoucherController.editVoucher);
router.post("/vouchers/delete/:id", authMiddleware, shopVoucherController.deleteVoucher);

// Review moderation routes
router.get("/reviews", authMiddleware, shopReviewController.showReviews);
router.post("/reviews/toggle/:id", authMiddleware, shopReviewController.toggleStatus);

// Shop Settings routes
router.get("/settings", authMiddleware, shopSettingsController.showSettings);
router.post("/settings/update", authMiddleware, shopSettingsController.updateProfile);
router.post("/settings/toggle-open", authMiddleware, shopSettingsController.toggleOpen);
router.post("/settings/banner", authMiddleware, uploadShopBanner.single("banner"), shopSettingsController.updateBanner);

// Revenue report route
router.get("/reports", authMiddleware, shopReportController.showReport);

module.exports = router;
