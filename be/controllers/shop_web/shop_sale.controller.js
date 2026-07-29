const productSaleService = require("../../services/productSale.service");

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

class ShopSaleController {
  async showSales(req, res) {
    try {
      const [{ sales, total, page, totalPages }, { products, variantsByProduct }] = await Promise.all([
        productSaleService.getSalesByShopPaginated(req.shop._id, req.query.page),
        productSaleService.getFormOptions(req.shop._id)
      ]);

      res.render("shop/sales", {
        sales,
        total,
        page,
        totalPages,
        products,
        variantsByProduct,
        firebaseConfig: buildFirebaseConfig(),
        shop: req.shop,
        user: req.user,
        title: "Quản lý Khuyến mãi",
        activeTab: "sales"
      });
    } catch (err) {
      console.error("Show sales controller error:", err.message);
      res.status(500).render("error", {
        message: "Failed to load sales: " + err.message,
        error: err
      });
    }
  }

  async addSale(req, res) {
    try {
      const result = await productSaleService.addSale(req.shop._id, req.body);
      return res.json({ status: "success", msg: "Thêm chương trình khuyến mãi thành công!", data: result });
    } catch (err) {
      console.error("Add sale controller error:", err.message);
      return res.status(400).json({ status: "error", msg: err.message });
    }
  }

  async editSale(req, res) {
    try {
      const { id } = req.params;
      const result = await productSaleService.editSale(req.shop._id, id, req.body);
      return res.json({ status: "success", msg: "Cập nhật khuyến mãi thành công!", data: result });
    } catch (err) {
      console.error("Edit sale controller error:", err.message);
      return res.status(400).json({ status: "error", msg: err.message });
    }
  }

  async deleteSale(req, res) {
    try {
      const { id } = req.params;
      await productSaleService.deleteSale(req.shop._id, id);
      return res.json({ status: "success", msg: "Xóa khuyến mãi thành công!" });
    } catch (err) {
      console.error("Delete sale controller error:", err.message);
      return res.status(400).json({ status: "error", msg: err.message });
    }
  }
}

module.exports = new ShopSaleController();
