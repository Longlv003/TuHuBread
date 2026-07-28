const productOptionService = require("../../services/productOption.service");

class ShopProductOptionController {
  async addOption(req, res) {
    try {
      const { productId } = req.params;
      const result = await productOptionService.addOption(req.shop._id, productId, req.body);
      return res.json({ status: "success", msg: "Thêm topping thành công!", data: result });
    } catch (err) {
      console.error("Add option controller error:", err.message);
      return res.status(400).json({ status: "error", msg: err.message });
    }
  }

  async editOption(req, res) {
    try {
      const { productId, id } = req.params;
      const result = await productOptionService.editOption(req.shop._id, productId, id, req.body);
      return res.json({ status: "success", msg: "Cập nhật topping thành công!", data: result });
    } catch (err) {
      console.error("Edit option controller error:", err.message);
      return res.status(400).json({ status: "error", msg: err.message });
    }
  }

  async deleteOption(req, res) {
    try {
      const { productId, id } = req.params;
      await productOptionService.deleteOption(req.shop._id, productId, id);
      return res.json({ status: "success", msg: "Xóa topping thành công!" });
    } catch (err) {
      console.error("Delete option controller error:", err.message);
      return res.status(400).json({ status: "error", msg: err.message });
    }
  }
}

module.exports = new ShopProductOptionController();
