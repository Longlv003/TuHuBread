const { voucherModel } = require("../models/voucher.model");

class VoucherRepository {
  async findById(id) {
    return voucherModel.findById(id);
  }

  async findByShopId(shopId) {
    return voucherModel.find({ shop_id: shopId, deleted_at: null }).sort({ createdAt: -1 });
  }

  async findByCode(code) {
    return voucherModel.findOne({ voucher_code: code });
  }

  async findPlatformVouchers() {
    return voucherModel.find({ voucher_type: "platform", deleted_at: null }).sort({ createdAt: -1 });
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
