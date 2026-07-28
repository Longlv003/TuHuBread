const productBatchService = require("../../services/productBatch.service");

class ShopProductBatchController {
  async addBatch(req, res) {
    try {
      const { productId } = req.params;
      const result = await productBatchService.addBatch(req.shop._id, productId, req.body);
      return res.json({ status: "success", msg: "Thêm lô hàng thành công!", data: result });
    } catch (err) {
      console.error("Add batch controller error:", err.message);
      return res.status(400).json({ status: "error", msg: err.message });
    }
  }

  async editBatch(req, res) {
    try {
      const { productId, id } = req.params;
      const result = await productBatchService.editBatch(req.shop._id, productId, id, req.body);
      return res.json({ status: "success", msg: "Cập nhật lô hàng thành công!", data: result });
    } catch (err) {
      console.error("Edit batch controller error:", err.message);
      return res.status(400).json({ status: "error", msg: err.message });
    }
  }

  async deleteBatch(req, res) {
    try {
      const { productId, id } = req.params;
      await productBatchService.deleteBatch(req.shop._id, productId, id);
      return res.json({ status: "success", msg: "Xóa lô hàng thành công!" });
    } catch (err) {
      console.error("Delete batch controller error:", err.message);
      return res.status(400).json({ status: "error", msg: err.message });
    }
  }
}

module.exports = new ShopProductBatchController();
