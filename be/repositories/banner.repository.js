const { bannerModel } = require("../models/banner.model");

class BannerRepository {
  async findById(id) {
    return bannerModel.findById(id);
  }

  async findAll() {
    return bannerModel.find({ deleted_at: null }).sort({ sort_order: 1 });
  }

  async findAllPaginated({ page = 1, limit = 50 }) {
    return bannerModel.find({ deleted_at: null })
      .sort({ sort_order: 1 })
      .skip((page - 1) * limit)
      .limit(limit);
  }

  async countAll() {
    return bannerModel.countDocuments({ deleted_at: null });
  }

  async findAllActive() {
    const now = new Date();
    return bannerModel.find({
      deleted_at: null,
      status: "active",
      $and: [
        { $or: [{ start_date: null }, { start_date: { $lte: now } }] },
        { $or: [{ end_date: null }, { end_date: { $gte: now } }] }
      ]
    }).sort({ sort_order: 1 });
  }

  async getMaxSortOrder() {
    const last = await bannerModel.findOne({ deleted_at: null }).sort({ sort_order: -1 }).select("sort_order");
    return last ? last.sort_order : -1;
  }

  async create(data) {
    return bannerModel.create(data);
  }

  async update(id, updateData) {
    return bannerModel.findByIdAndUpdate(id, updateData, { new: true });
  }

  async softDelete(id) {
    return bannerModel.findByIdAndUpdate(id, { deleted_at: new Date(), status: "inactive" }, { new: true });
  }
}

module.exports = new BannerRepository();
