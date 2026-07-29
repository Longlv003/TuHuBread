const productVariantService = require("../../services/productVariant.service");

class ShopProductVariantController {
  async addVariant(req, res) {
    try {
      const { productId } = req.params;
      const image = req.file ? `/images/products/${req.file.filename}` : null;
      const result = await productVariantService.addVariant(req.shop._id, productId, { ...req.body, image });
      return res.json({ status: "success", msg: "Thêm biến thể thành công!", data: result });
    } catch (err) {
      console.error("Add variant controller error:", err.message);
      return res.status(400).json({ status: "error", msg: err.message });
    }
  }

  async editVariant(req, res) {
    try {
      const { productId, id } = req.params;
      const image = req.file ? `/images/products/${req.file.filename}` : undefined;
      const result = await productVariantService.editVariant(req.shop._id, productId, id, { ...req.body, image });
      return res.json({ status: "success", msg: "Cập nhật biến thể thành công!", data: result });
    } catch (err) {
      console.error("Edit variant controller error:", err.message);
      return res.status(400).json({ status: "error", msg: err.message });
    }
  }

  async deleteVariant(req, res) {
    try {
      const { productId, id } = req.params;
      await productVariantService.deleteVariant(req.shop._id, productId, id);
      return res.json({ status: "success", msg: "Xóa biến thể thành công!" });
    } catch (err) {
      console.error("Delete variant controller error:", err.message);
      return res.status(400).json({ status: "error", msg: err.message });
    }
  }
}

module.exports = new ShopProductVariantController();
