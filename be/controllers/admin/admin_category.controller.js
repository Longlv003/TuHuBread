const globalCategoryService = require("../../services/globalCategory.service");

class AdminCategoryController {
  async showCategories(req, res) {
    try {
      const categories = await globalCategoryService.getAllCategories();

      res.render("admin/categories", {
        categories,
        admin: req.admin,
        title: "Danh mục toàn hệ thống",
        activeTab: "categories"
      });
    } catch (err) {
      console.error("Show admin categories controller error:", err.message);
      res.status(500).render("error", {
        message: "Failed to load categories: " + err.message,
        error: err
      });
    }
  }

  async addCategory(req, res) {
    try {
      const { categoryName, status } = req.body;
      const categoryIcon = req.file ? `/images/categories/${req.file.filename}` : null;

      const result = await globalCategoryService.addCategory({ categoryName, status, categoryIcon });
      return res.json({ status: "success", msg: "Thêm danh mục thành công!", data: result });
    } catch (err) {
      console.error("Add admin category controller error:", err.message);
      return res.status(400).json({ status: "error", msg: err.message });
    }
  }

  async editCategory(req, res) {
    try {
      const { id } = req.params;
      const { categoryName, status } = req.body;
      const categoryIcon = req.file ? `/images/categories/${req.file.filename}` : null;

      const result = await globalCategoryService.updateCategory(id, { categoryName, status, categoryIcon });
      return res.json({ status: "success", msg: "Cập nhật danh mục thành công!", data: result });
    } catch (err) {
      console.error("Edit admin category controller error:", err.message);
      return res.status(400).json({ status: "error", msg: err.message });
    }
  }

  async deleteCategory(req, res) {
    try {
      const { id } = req.params;
      await globalCategoryService.deleteCategory(id);
      return res.json({ status: "success", msg: "Xóa danh mục thành công!" });
    } catch (err) {
      console.error("Delete admin category controller error:", err.message);
      return res.status(400).json({ status: "error", msg: err.message });
    }
  }
}

module.exports = new AdminCategoryController();
