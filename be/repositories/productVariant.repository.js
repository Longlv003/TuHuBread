const { productVariantModel } = require("../models/productVariant.model");

class ProductVariantRepository {
  async findById(id) {
    return productVariantModel.findById(id);
  }

  async findByProductId(productId) {
    return productVariantModel.find({ product_id: productId, deleted_at: null }).sort({ createdAt: 1 });
  }

  async findByProductIds(productIds) {
    return productVariantModel.find({ product_id: { $in: productIds }, deleted_at: null }).sort({ createdAt: 1 });
  }

  async countActiveByProductId(productId) {
    return productVariantModel.countDocuments({ product_id: productId, status: { $ne: "inactive" }, deleted_at: null });
  }

  async create(data) {
    return productVariantModel.create(data);
  }

  async update(id, updateData) {
    return productVariantModel.findByIdAndUpdate(id, updateData, { new: true });
  }

  async softDelete(id) {
    return productVariantModel.findByIdAndUpdate(id, { deleted_at: new Date(), status: "inactive" }, { new: true });
  }
}

module.exports = new ProductVariantRepository();
