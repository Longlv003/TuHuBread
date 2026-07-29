const { productAttributeModel } = require("../models/productAttribute.model");

class ProductAttributeRepository {
  async findById(id) {
    return productAttributeModel.findById(id);
  }

  async findByProductId(productId) {
    return productAttributeModel.find({ product_id: productId, deleted_at: null }).sort({ sort_order: 1 });
  }

  async getMaxSortOrder(productId) {
    const last = await productAttributeModel
      .findOne({ product_id: productId, deleted_at: null })
      .sort({ sort_order: -1 })
      .select("sort_order");
    return last ? last.sort_order : -1;
  }

  async create(data) {
    return productAttributeModel.create(data);
  }

  async update(id, updateData) {
    return productAttributeModel.findByIdAndUpdate(id, updateData, { new: true });
  }

  async softDelete(id) {
    return productAttributeModel.findByIdAndUpdate(id, { deleted_at: new Date(), status: "inactive" }, { new: true });
  }
}

module.exports = new ProductAttributeRepository();
