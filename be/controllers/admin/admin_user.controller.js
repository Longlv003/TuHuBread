const adminUserService = require("../../services/adminUser.service");

class AdminUserController {
  async showUsers(req, res) {
    try {
      const { search, role, status, page } = req.query;
      const result = await adminUserService.getUsers({ search, role, status, page });

      res.render("admin/users", {
        ...result,
        search: search || "",
        role: role || "all",
        status: status || "all",
        admin: req.admin,
        title: "Quản lý Người dùng",
        activeTab: "users"
      });
    } catch (err) {
      console.error("Show users controller error:", err.message);
      res.status(500).render("error", {
        message: "Failed to load users: " + err.message,
        error: err
      });
    }
  }

  async updateUser(req, res) {
    try {
      const { id } = req.params;
      const result = await adminUserService.updateUser(id, req.body);
      return res.json({ status: "success", msg: "Cập nhật người dùng thành công!", data: result });
    } catch (err) {
      console.error("Update user controller error:", err.message);
      return res.status(400).json({ status: "error", msg: err.message });
    }
  }

  async toggleLock(req, res) {
    try {
      const { id } = req.params;
      const result = await adminUserService.toggleLock(id);
      return res.json({ status: "success", msg: "Cập nhật trạng thái tài khoản thành công!", data: result });
    } catch (err) {
      console.error("Toggle lock controller error:", err.message);
      return res.status(400).json({ status: "error", msg: err.message });
    }
  }
}

module.exports = new AdminUserController();
