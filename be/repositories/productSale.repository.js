const { productSaleModel } = require("../models/productSale.model");

class ProductSaleRepository {
  async findById(id) {
    return productSaleModel.findById(id);
  }

  async findByIdPopulated(id) {
    return productSaleModel.findById(id).populate("product_id").populate("variant_id");
  }

  async findByProductIds(productIds) {
    return productSaleModel.find({ product_id: { $in: productIds }, deleted_at: null })
      .populate("product_id", "product_name")
      .populate("variant_id", "variant_name")
      .sort({ createdAt: -1 });
  }

  async create(data) {
    return productSaleModel.create(data);
  }

  async update(id, updateData) {
    return productSaleModel.findByIdAndUpdate(id, updateData, { new: true });
  }

  async softDelete(id) {
    return productSaleModel.findByIdAndUpdate(id, { deleted_at: new Date(), status: "inactive" }, { new: true });
  }
}

module.exports = new ProductSaleRepository();
