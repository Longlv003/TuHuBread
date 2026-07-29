const accountRepository = require("../repositories/account.repository");

const PAGE_SIZE = 10;

class AdminUserService {
  async getUsers({ search, role, status, page = 1 }) {
    const parsedPage = Math.max(parseInt(page) || 1, 1);
    const [users, total] = await Promise.all([
      accountRepository.findAllPaginated({ search, role, status, page: parsedPage, limit: PAGE_SIZE }),
      accountRepository.countAll({ search, role, status })
    ]);

    return {
      users,
      total,
      page: parsedPage,
      totalPages: Math.max(Math.ceil(total / PAGE_SIZE), 1)
    };
  }

  async updateUser(id, data) {
    const { fullName, phone } = data;
    const existing = await accountRepository.findById(id);
    if (!existing) {
      throw new Error("User not found");
    }

    const updateData = {};
    if (fullName) updateData.full_name = fullName.trim();
    if (phone !== undefined) updateData.phone = phone || null;

    return accountRepository.update(id, updateData);
  }

  async toggleLock(id) {
    const existing = await accountRepository.findById(id);
    if (!existing) {
      throw new Error("User not found");
    }
    if (existing.role === "admin") {
      throw new Error("Không thể khóa tài khoản admin khác");
    }

    const newStatus = existing.status === "blocked" ? "active" : "blocked";
    return accountRepository.update(id, { status: newStatus });
  }
}

module.exports = new AdminUserService();
