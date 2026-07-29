const { productOptionModel } = require("../models/productOption.model");

class ProductOptionRepository {
  async findById(id) {
    return productOptionModel.findById(id);
  }

  async findByProductId(productId) {
    return productOptionModel.find({ product_id: productId, deleted_at: null }).sort({ createdAt: 1 });
  }

  async create(data) {
    return productOptionModel.create(data);
  }

  async update(id, updateData) {
    return productOptionModel.findByIdAndUpdate(id, updateData, { new: true });
  }

  async softDelete(id) {
    return productOptionModel.findByIdAndUpdate(id, { deleted_at: new Date(), status: "inactive" }, { new: true });
  }
}

module.exports = new ProductOptionRepository();
