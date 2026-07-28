const productAttributeService = require("../../services/productAttribute.service");

class ShopProductAttributeController {
  async addAttribute(req, res) {
    try {
      const { productId } = req.params;
      const result = await productAttributeService.addAttribute(req.shop._id, productId, req.body);
      return res.json({ status: "success", msg: "Thêm thuộc tính thành công!", data: result });
    } catch (err) {
      console.error("Add attribute controller error:", err.message);
      return res.status(400).json({ status: "error", msg: err.message });
    }
  }

  async editAttribute(req, res) {
    try {
      const { productId, id } = req.params;
      const result = await productAttributeService.editAttribute(req.shop._id, productId, id, req.body);
      return res.json({ status: "success", msg: "Cập nhật thuộc tính thành công!", data: result });
    } catch (err) {
      console.error("Edit attribute controller error:", err.message);
      return res.status(400).json({ status: "error", msg: err.message });
    }
  }

  async deleteAttribute(req, res) {
    try {
      const { productId, id } = req.params;
      await productAttributeService.deleteAttribute(req.shop._id, productId, id);
      return res.json({ status: "success", msg: "Xóa thuộc tính thành công!" });
    } catch (err) {
      console.error("Delete attribute controller error:", err.message);
      return res.status(400).json({ status: "error", msg: err.message });
    }
  }
}

module.exports = new ShopProductAttributeController();
