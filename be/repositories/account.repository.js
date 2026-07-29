const { userModel } = require("../models/user.model");

class AccountRepository {
  async findById(id) {
    return userModel.findById(id);
  }

  async findByFirebaseUid(uid) {
    return userModel.findOne({ firebase_uid: uid });
  }

  async findByEmail(email) {
    return userModel.findOne({ email: email });
  }

  async create(userData) {
    return userModel.create(userData);
  }

  async update(id, updateData) {
    return userModel.findByIdAndUpdate(id, updateData, { new: true });
  }

  async deleteById(id) {
    return userModel.findByIdAndDelete(id);
  }

  buildFilters({ search, role, status }) {
    const filters = { deleted_at: null };
    if (search) {
      filters.$or = [
        { full_name: { $regex: search, $options: "i" } },
        { email: { $regex: search, $options: "i" } }
      ];
    }
    if (role && role !== "all") filters.role = role;
    if (status && status !== "all") filters.status = status;
    return filters;
  }

  async findAllPaginated({ search, role, status, page = 1, limit = 20 }) {
    const filters = this.buildFilters({ search, role, status });
    return userModel.find(filters)
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(limit);
  }

  async countAll({ search, role, status }) {
    const filters = this.buildFilters({ search, role, status });
    return userModel.countDocuments(filters);
  }
}

module.exports = new AccountRepository();
