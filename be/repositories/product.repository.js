const { productModel } = require("../models/product.model");

class ProductRepository {
  async findById(id) {
    return productModel.findById(id);
  }

  async findByIdScoped(id, shopId) {
    return productModel.findOne({ _id: id, shop_id: shopId, deleted_at: null });
  }

  async findByShopId(shopId) {
    return productModel.find({ shop_id: shopId, deleted_at: null })
      .populate("global_category_id")
      .sort({ createdAt: -1 });
  }

  async findByShopIdPaginated(shopId, { page = 1, limit = 50 }) {
    return productModel.find({ shop_id: shopId, deleted_at: null })
      .populate("global_category_id")
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(limit);
  }

  async countByShopId(shopId) {
    return productModel.countDocuments({ shop_id: shopId, deleted_at: null });
  }

  async findIdsByShopId(shopId) {
    const products = await productModel.find({ shop_id: shopId, deleted_at: null }).select("_id");
    return products.map(p => p._id);
  }

  async create(data) {
    return productModel.create(data);
  }

  async update(id, updateData) {
    return productModel.findByIdAndUpdate(id, updateData, { new: true });
  }

  async softDelete(id) {
    return productModel.findByIdAndUpdate(id, { deleted_at: new Date(), status: "inactive" }, { new: true });
  }

  async hardDelete(id) {
    return productModel.findByIdAndDelete(id);
  }
}

module.exports = new ProductRepository();
