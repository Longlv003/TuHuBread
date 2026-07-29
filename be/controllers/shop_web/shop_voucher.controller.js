const voucherService = require("../../services/voucher.service");

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

class ShopVoucherController {
  async showVouchers(req, res) {
    try {
      const { vouchers, total, page, totalPages } = await voucherService.getVouchersByShopPaginated(req.shop._id, req.query.page);

      res.render("shop/vouchers", {
        vouchers,
        total,
        page,
        totalPages,
        firebaseConfig: buildFirebaseConfig(),
        shop: req.shop,
        user: req.user,
        title: "Quản lý Mã giảm giá",
        activeTab: "vouchers"
      });
    } catch (err) {
      console.error("Show vouchers controller error:", err.message);
      res.status(500).render("error", {
        message: "Failed to load vouchers: " + err.message,
        error: err
      });
    }
  }

  async addVoucher(req, res) {
    try {
      const result = await voucherService.addVoucher(req.shop._id, req.body);
      return res.json({ status: "success", msg: "Thêm mã giảm giá thành công!", data: result });
    } catch (err) {
      console.error("Add voucher controller error:", err.message);
      return res.status(400).json({ status: "error", msg: err.message });
    }
  }

  async editVoucher(req, res) {
    try {
      const { id } = req.params;
      const result = await voucherService.editVoucher(req.shop._id, id, req.body);
      return res.json({ status: "success", msg: "Cập nhật mã giảm giá thành công!", data: result });
    } catch (err) {
      console.error("Edit voucher controller error:", err.message);
      return res.status(400).json({ status: "error", msg: err.message });
    }
  }

  async deleteVoucher(req, res) {
    try {
      const { id } = req.params;
      await voucherService.deleteVoucher(req.shop._id, id);
      return res.json({ status: "success", msg: "Xóa mã giảm giá thành công!" });
    } catch (err) {
      console.error("Delete voucher controller error:", err.message);
      return res.status(400).json({ status: "error", msg: err.message });
    }
  }
}

module.exports = new ShopVoucherController();
