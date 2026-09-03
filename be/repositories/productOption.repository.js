const { productOptionModel } = require("../models/productOption.model");

class ProductOptionRepository {
  async findById(id) {
    return productOptionModel.findById(id);
  }

  async findByProductId(productId) {
    return productOptionModel.find({ product_id: productId, deleted_at: null }).sort({ createdAt: 1 });
  }

  async existsByProductIdAndSlug(productId, slug, excludeOptionId) {
    const query = { product_id: productId, option_slug: slug, deleted_at: null };
    if (excludeOptionId) {
      query._id = { $ne: excludeOptionId };
    }
    const doc = await productOptionModel.findOne(query).select("_id");
    return !!doc;
  }

  /** Kiểm tra trùng TÊN topping (không phân biệt hoa/thường) trong cùng 1 sản phẩm. */
  async existsByProductIdAndName(productId, optionName, excludeOptionId) {
    const escaped = optionName.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const query = {
      product_id: productId,
      option_name: { $regex: `^${escaped}$`, $options: "i" },
      deleted_at: null,
    };
    if (excludeOptionId) {
      query._id = { $ne: excludeOptionId };
    }
    const doc = await productOptionModel.findOne(query).select("_id");
    return !!doc;
  }

  async create(data) {
    return productOptionModel.create(data);
  }

  async update(id, updateData) {
    return productOptionModel.findByIdAndUpdate(id, updateData, { new: true, runValidators: true });
  }

  async softDelete(id) {
    return productOptionModel.findByIdAndUpdate(id, { deleted_at: new Date(), status: "inactive" }, { new: true, runValidators: true });
  }
}

module.exports = new ProductOptionRepository();
