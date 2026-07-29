const bannerService = require("../../services/banner.service");

class AdminBannerController {
  async showBanners(req, res) {
    try {
      const { banners, total, page, totalPages } = await bannerService.getAllBannersPaginated(req.query.page);

      res.render("admin/banners", {
        banners,
        total,
        page,
        totalPages,
        admin: req.admin,
        title: "Quản lý Banner",
        activeTab: "banners"
      });
    } catch (err) {
      console.error("Show banners controller error:", err.message);
      res.status(500).render("error", {
        message: "Failed to load banners: " + err.message,
        error: err
      });
    }
  }

  async addBanner(req, res) {
    try {
      const image = req.file ? `/images/banners/${req.file.filename}` : null;
      const result = await bannerService.addBanner({ ...req.body, image });
      return res.json({ status: "success", msg: "Thêm banner thành công!", data: result });
    } catch (err) {
      console.error("Add banner controller error:", err.message);
      return res.status(400).json({ status: "error", msg: err.message });
    }
  }

  async editBanner(req, res) {
    try {
      const { id } = req.params;
      const image = req.file ? `/images/banners/${req.file.filename}` : undefined;
      const result = await bannerService.updateBanner(id, { ...req.body, image });
      return res.json({ status: "success", msg: "Cập nhật banner thành công!", data: result });
    } catch (err) {
      console.error("Edit banner controller error:", err.message);
      return res.status(400).json({ status: "error", msg: err.message });
    }
  }

  async deleteBanner(req, res) {
    try {
      const { id } = req.params;
      await bannerService.deleteBanner(id);
      return res.json({ status: "success", msg: "Xóa banner thành công!" });
    } catch (err) {
      console.error("Delete banner controller error:", err.message);
      return res.status(400).json({ status: "error", msg: err.message });
    }
  }
}

module.exports = new AdminBannerController();
