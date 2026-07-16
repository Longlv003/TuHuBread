const shopCategoryService = require("../../services/shopCategory.service");

class ShopCategoryController {
  /**
   * Render Categories Page
   */
  async showCategories(req, res) {
    try {
      const categories = await shopCategoryService.getCategoriesByShop(req.shop._id);

      const firebaseConfig = {
        apiKey: process.env.FIREBASE_API_KEY,
        authDomain: process.env.FIREBASE_AUTH_DOMAIN,
        projectId: process.env.FIREBASE_PROJECT_ID,
        storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
        messagingSenderId: process.env.FIREBASE_MESSAGING_SENDER_ID,
        appId: process.env.FIREBASE_APP_ID
      };

      res.render("shop/categories", {
        categories,
        firebaseConfig,
        shop: req.shop,
        user: req.user,
        title: "Quản lý Danh mục",
        activeTab: "categories"
      });
    } catch (err) {
      console.error("Show categories controller error:", err.message);
      res.status(500).render("error", {
        message: "Failed to load categories: " + err.message,
        error: err
      });
    }
  }

  /**
   * API Post: Add a new category
   */
  async addCategory(req, res) {
    try {
      const { categoryName, sortOrder, status } = req.body;
      const categoryIcon = req.file ? `/images/categories/${req.file.filename}` : null;

      const result = await shopCategoryService.addCategory(req.shop._id, {
        categoryName,
        sortOrder,
        status,
        categoryIcon
      });

      return res.json({ status: "success", msg: "Category added successfully!", data: result });
    } catch (err) {
      console.error("Add category controller error:", err.message);
      return res.status(400).json({ status: "error", msg: err.message });
    }
  }

  /**
   * API Post: Edit an existing category
   */
  async editCategory(req, res) {
    try {
      const { id } = req.params;
      const { categoryName, sortOrder, status } = req.body;
      const categoryIcon = req.file ? `/images/categories/${req.file.filename}` : null;

      const result = await shopCategoryService.updateCategory(id, {
        categoryName,
        sortOrder,
        status,
        categoryIcon
      });

      return res.json({ status: "success", msg: "Category updated successfully!", data: result });
    } catch (err) {
      console.error("Edit category controller error:", err.message);
      return res.status(400).json({ status: "error", msg: err.message });
    }
  }

  /**
   * API Post: Soft delete a category
   */
  async deleteCategory(req, res) {
    try {
      const { id } = req.params;
      await shopCategoryService.deleteCategory(id);
      return res.json({ status: "success", msg: "Category deleted successfully!" });
    } catch (err) {
      console.error("Delete category controller error:", err.message);
      return res.status(400).json({ status: "error", msg: err.message });
    }
  }
}

module.exports = new ShopCategoryController();
