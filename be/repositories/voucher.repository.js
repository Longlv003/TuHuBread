const { voucherModel } = require("../models/voucher.model");

class VoucherRepository {
  async findById(id) {
    return voucherModel.findById(id);
  }

  async findByShopId(shopId) {
    return voucherModel.find({ shop_id: shopId, deleted_at: null }).sort({ createdAt: -1 });
  }

  async findByShopIdPaginated(shopId, { page = 1, limit = 50 }) {
    return voucherModel.find({ shop_id: shopId, deleted_at: null })
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(limit);
  }

  async countByShopId(shopId) {
    return voucherModel.countDocuments({ shop_id: shopId, deleted_at: null });
  }

  async findByCode(code) {
    return voucherModel.findOne({ voucher_code: code });
  }

  async findPlatformVouchers() {
    return voucherModel.find({ voucher_type: "platform", deleted_at: null }).sort({ createdAt: -1 });
  }

  async findPlatformVouchersPaginated({ page = 1, limit = 50 }) {
    return voucherModel.find({ voucher_type: "platform", deleted_at: null })
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(limit);
  }

  async countPlatformVouchers() {
    return voucherModel.countDocuments({ voucher_type: "platform", deleted_at: null });
  }

  async create(data) {
    return voucherModel.create(data);
  }

  async update(id, updateData) {
    return voucherModel.findByIdAndUpdate(id, updateData, { new: true });
  }

  async softDelete(id) {
    return voucherModel.findByIdAndUpdate(id, { deleted_at: new Date(), status: "inactive" }, { new: true });
  }
}

module.exports = new VoucherRepository();
