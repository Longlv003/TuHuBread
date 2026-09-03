const { auth } = require("../configs/firebase.config");
const accountRepository = require("../repositories/account.repository");
const { normalizePhone, requireText } = require("../utils/validate.util");

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
    // requireText chặn cả chuỗi toàn khoảng trắng: "   ".trim() ra rỗng, mà
    // full_name lại là trường bắt buộc trong schema.
    if (fullName !== undefined) {
      updateData.full_name = requireText(fullName, "Họ tên", { maxLength: 120 });
    }
    if (phone !== undefined) {
      updateData.phone = phone ? normalizePhone(phone) : null;
    }

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
    const updated = await accountRepository.update(id, { status: newStatus });

    // Đồng bộ sang Firebase: chỉ đổi status trong MongoDB là chưa đủ vì ID token
    // đã cấp cho app vẫn sống thêm tối đa 1 giờ và session cookie của portal web
    // sống tới 5 ngày. disableUser chặn đăng nhập mới, revokeRefreshTokens làm
    // mọi phiên hiện có mất hiệu lực ngay lập tức.
    if (existing.firebase_uid) {
      try {
        await auth.updateUser(existing.firebase_uid, { disabled: newStatus === "blocked" });
        if (newStatus === "blocked") {
          await auth.revokeRefreshTokens(existing.firebase_uid);
        }
      } catch (err) {
        // Không rollback trạng thái trong DB: middleware đã tự chặn dựa trên
        // status nên khoá vẫn có hiệu lực, chỉ là phiên cũ hết chậm hơn.
        console.error("[adminUser.toggleLock] Sync Firebase failed:", err.message);
      }
    }

    return updated;
  }
}

module.exports = new AdminUserService();
