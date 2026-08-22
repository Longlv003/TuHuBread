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

  async existsByProductIdAndSlug(productId, slug, excludeVariantId) {
    const query = { product_id: productId, variant_slug: slug, deleted_at: null };
    if (excludeVariantId) {
      query._id = { $ne: excludeVariantId };
    }
    const doc = await productVariantModel.findOne(query).select("_id");
    return !!doc;
  }

  /**
   * Kiểm tra trùng TÊN biến thể (không phân biệt hoa/thường, đã trim) trong
   * cùng 1 sản phẩm — khác với existsByProductIdAndSlug vốn chỉ đảm bảo slug
   * (định danh nội bộ) là duy nhất chứ không ngăn 2 biến thể hiển thị cùng
   * tên "M" gây nhầm lẫn cho cả chủ shop lẫn khách hàng khi chọn mua.
   */
  async existsByProductIdAndName(productId, variantName, excludeVariantId) {
    const escaped = variantName.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const query = {
      product_id: productId,
      variant_name: { $regex: `^${escaped}$`, $options: "i" },
      deleted_at: null,
    };
    if (excludeVariantId) {
      query._id = { $ne: excludeVariantId };
    }
    const doc = await productVariantModel.findOne(query).select("_id");
    return !!doc;
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

  async hardDelete(id) {
    return productVariantModel.findByIdAndDelete(id);
  }
}

module.exports = new ProductVariantRepository();
