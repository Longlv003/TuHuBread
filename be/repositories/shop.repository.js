const { shopModel } = require("../models/shop.model");

class ShopRepository {
  async findById(id) {
    return shopModel.findById(id).populate("owner_user_id");
  }

  async findByOwnerId(ownerUserId) {
    return shopModel.findOne({ owner_user_id: ownerUserId });
  }

  async findBySlug(slug) {
    return shopModel.findOne({ shop_slug: slug });
  }

  async create(shopData) {
    return shopModel.create(shopData);
  }

  async update(id, updateData) {
    return shopModel.findByIdAndUpdate(id, updateData, { new: true });
  }

  async findAllActive() {
    return shopModel.find({ status: "active", deleted_at: null });
  }

  async findAll() {
    return shopModel.find({ deleted_at: null }).populate("owner_user_id", "full_name email phone").sort({ createdAt: -1 });
  }
}

module.exports = new ShopRepository();
