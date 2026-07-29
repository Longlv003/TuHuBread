const { productBatchModel } = require("../models/productBatch.model");

class ProductBatchRepository {
  async findById(id) {
    return productBatchModel.findById(id);
  }

  async findByProductId(productId) {
    return productBatchModel.find({ product_id: productId, deleted_at: null })
      .populate("variant_id")
      .sort({ expired_at: 1 });
  }

  async create(data) {
    return productBatchModel.create(data);
  }

  async update(id, updateData) {
    return productBatchModel.findByIdAndUpdate(id, updateData, { new: true });
  }

  async softDelete(id) {
    return productBatchModel.findByIdAndUpdate(id, { deleted_at: new Date() }, { new: true });
  }
}

module.exports = new ProductBatchRepository();
