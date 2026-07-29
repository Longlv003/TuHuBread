const voucherService = require("../../services/voucher.service");

class AdminVoucherController {
  async showVouchers(req, res) {
    try {
      const { vouchers, total, page, totalPages } = await voucherService.getPlatformVouchersPaginated(req.query.page);

      res.render("admin/vouchers", {
        vouchers,
        total,
        page,
        totalPages,
        admin: req.admin,
        title: "Voucher toàn sàn",
        activeTab: "vouchers"
      });
    } catch (err) {
      console.error("Show admin vouchers controller error:", err.message);
      res.status(500).render("error", {
        message: "Failed to load vouchers: " + err.message,
        error: err
      });
    }
  }

  async addVoucher(req, res) {
    try {
      const result = await voucherService.addPlatformVoucher(req.body);
      return res.json({ status: "success", msg: "Thêm mã giảm giá thành công!", data: result });
    } catch (err) {
      console.error("Add admin voucher controller error:", err.message);
      return res.status(400).json({ status: "error", msg: err.message });
    }
  }

  async editVoucher(req, res) {
    try {
      const { id } = req.params;
      const result = await voucherService.editPlatformVoucher(id, req.body);
      return res.json({ status: "success", msg: "Cập nhật mã giảm giá thành công!", data: result });
    } catch (err) {
      console.error("Edit admin voucher controller error:", err.message);
      return res.status(400).json({ status: "error", msg: err.message });
    }
  }

  async deleteVoucher(req, res) {
    try {
      const { id } = req.params;
      await voucherService.deletePlatformVoucher(id);
      return res.json({ status: "success", msg: "Xóa mã giảm giá thành công!" });
    } catch (err) {
      console.error("Delete admin voucher controller error:", err.message);
      return res.status(400).json({ status: "error", msg: err.message });
    }
  }
}

module.exports = new AdminVoucherController();
