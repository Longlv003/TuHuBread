const { shopCategoryModel } = require("../models/shopCategory.model");

class ShopCategoryRepository {
  async findById(id) {
    return shopCategoryModel.findById(id);
  }

  async findByShopId(shopId) {
    return shopCategoryModel.find({ shop_id: shopId }).sort({ sort_order: 1 });
  }

  async findBySlugAndShopId(slug, shopId) {
    return shopCategoryModel.findOne({
      shop_id: shopId,
      category_slug: slug,
      deleted_at: null
    });
  }

  async getMaxSortOrder(shopId) {
    const lastCategory = await shopCategoryModel
      .findOne({ shop_id: shopId, deleted_at: null })
      .sort({ sort_order: -1 })
      .select("sort_order");
    return lastCategory ? lastCategory.sort_order : -1;
  }

  async create(data) {
    return shopCategoryModel.create(data);
  }

  async update(id, updateData) {
    return shopCategoryModel.findByIdAndUpdate(id, updateData, { new: true });
  }

  async softDelete(id) {
    return shopCategoryModel.findByIdAndUpdate(id, { deleted_at: new Date() }, { new: true });
  }
}

module.exports = new ShopCategoryRepository();
