const { globalCategoryModel } = require("../models/globalCategory.model");

class GlobalCategoryRepository {
  async findById(id) {
    return globalCategoryModel.findById(id);
  }

  async findAllActive() {
    return globalCategoryModel.find({ status: "active", deleted_at: null });
  }

  async findAll() {
    return globalCategoryModel.find({ deleted_at: null }).sort({ category_name: 1 });
  }

  async findAllPaginated({ page = 1, limit = 50 }) {
    return globalCategoryModel.find({ deleted_at: null })
      .sort({ category_name: 1 })
      .skip((page - 1) * limit)
      .limit(limit);
  }

  async countAll() {
    return globalCategoryModel.countDocuments({ deleted_at: null });
  }

  async findBySlug(slug) {
    return globalCategoryModel.findOne({ category_slug: slug, deleted_at: null });
  }

  async create(data) {
    return globalCategoryModel.create(data);
  }

  async update(id, updateData) {
    return globalCategoryModel.findByIdAndUpdate(id, updateData, { new: true });
  }

  async softDelete(id) {
    return globalCategoryModel.findByIdAndUpdate(id, { deleted_at: new Date(), status: "inactive" }, { new: true });
  }
}

module.exports = new GlobalCategoryRepository();
