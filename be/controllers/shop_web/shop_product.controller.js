const productService = require("../../services/product.service");
const globalCategoryRepository = require("../../repositories/globalCategory.repository");

function buildFirebaseConfig() {
  return {
    apiKey: process.env.FIREBASE_API_KEY,
    authDomain: process.env.FIREBASE_AUTH_DOMAIN,
    projectId: process.env.FIREBASE_PROJECT_ID,
    storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
    messagingSenderId: process.env.FIREBASE_MESSAGING_SENDER_ID,
    appId: process.env.FIREBASE_APP_ID
  };
}

/**
 * Hạn sử dụng gần nhất còn hiệu lực cho từng biến thể — lấy từ các lô hàng
 * (được tự tạo ngầm mỗi khi nhập tồn kho kèm HSD), để hiện thẳng lên bảng
 * biến thể thay vì phải mở 1 tab Lô hàng riêng.
 */
function buildVariantExpiryMap(batches) {
  const map = {};
  for (const b of batches) {
    if (!b.variant_id || b.status !== "active") continue;
    const variantId = String(b.variant_id._id || b.variant_id);
    if (!map[variantId] || b.expired_at < map[variantId]) {
      map[variantId] = b.expired_at;
    }
  }
  return map;
}

class ShopProductController {
  async showProducts(req, res) {
    try {
      const [{ products, total, page, totalPages }, globalCategories] = await Promise.all([
        productService.getProductsByShopPaginated(req.shop._id, req.query.page),
        globalCategoryRepository.findAllActive()
      ]);

      res.render("shop/products", {
        products,
        total,
        page,
        totalPages,
        globalCategories,
        firebaseConfig: buildFirebaseConfig(),
        shop: req.shop,
        user: req.user,
        title: "Quản lý Sản phẩm",
        activeTab: "products"
      });
    } catch (err) {
      console.error("Show products controller error:", err.message);
      res.status(500).render("error", {
        message: "Failed to load products: " + err.message,
        error: err
      });
    }
  }

  async showProductDetail(req, res) {
    try {
      const { product, variants, options, batches } = await productService.getProductDetail(req.shop._id, req.params.id);
      const globalCategories = await globalCategoryRepository.findAllActive();

      res.render("shop/product_detail", {
        product,
        variants,
        options,
        variantExpiry: buildVariantExpiryMap(batches),
        globalCategories,
        firebaseConfig: buildFirebaseConfig(),
        shop: req.shop,
        user: req.user,
        title: `Chi tiết: ${product.product_name}`,
        activeTab: "products"
      });
    } catch (err) {
      console.error("Show product detail controller error:", err.message);
      res.status(404).render("error", {
        message: "Failed to load product: " + err.message,
        error: err
      });
    }
  }

  async addProduct(req, res) {
    try {
      const variantImage = req.file ? `/images/products/${req.file.filename}` : null;
      const result = await productService.addProduct(req.shop._id, { ...req.body, variantImage });
      return res.json({ status: "success", msg: "Thêm sản phẩm thành công!", data: result });
    } catch (err) {
      console.error("Add product controller error:", err.message);
      return res.status(400).json({ status: "error", msg: err.message });
    }
  }

  async editProduct(req, res) {
    try {
      const { id } = req.params;
      const result = await productService.updateProduct(req.shop._id, id, req.body);
      return res.json({ status: "success", msg: "Cập nhật sản phẩm thành công!", data: result });
    } catch (err) {
      console.error("Edit product controller error:", err.message);
      return res.status(400).json({ status: "error", msg: err.message });
    }
  }

  async deleteProduct(req, res) {
    try {
      const { id } = req.params;
      await productService.deleteProduct(req.shop._id, id);
      return res.json({ status: "success", msg: "Xóa sản phẩm thành công!" });
    } catch (err) {
      console.error("Delete product controller error:", err.message);
      return res.status(400).json({ status: "error", msg: err.message });
    }
  }
}

module.exports = new ShopProductController();
