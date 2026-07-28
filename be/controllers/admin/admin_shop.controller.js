const shopService = require("../../services/shop.service");
const authService = require("../../services/auth.service");

class AdminShopController {
  async showShops(req, res) {
    try {
      const shops = await shopService.getAllShops();

      res.render("admin/shops", {
        shops,
        admin: req.admin,
        title: "Quản lý Shop",
        activeTab: "shops"
      });
    } catch (err) {
      console.error("Show admin shops controller error:", err.message);
      res.status(500).render("error", {
        message: "Failed to load shops: " + err.message,
        error: err
      });
    }
  }

  async addShop(req, res) {
    try {
      const result = await authService.registerShop(req.body);
      return res.json({ status: "success", msg: "Tạo chi nhánh mới thành công!", data: result });
    } catch (err) {
      console.error("Add admin shop controller error:", err.message);
      return res.status(400).json({ status: "error", msg: err.message });
    }
  }

  async editShop(req, res) {
    try {
      const { id } = req.params;
      const result = await shopService.adminUpdateShop(id, req.body);
      return res.json({ status: "success", msg: "Cập nhật chi nhánh thành công!", data: result });
    } catch (err) {
      console.error("Edit admin shop controller error:", err.message);
      return res.status(400).json({ status: "error", msg: err.message });
    }
  }
}

module.exports = new AdminShopController();
