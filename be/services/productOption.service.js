const productRepository = require("../repositories/product.repository");
const productOptionRepository = require("../repositories/productOption.repository");
const { toSlug } = require("../utils/slug.util");

class ProductOptionService {
  /**
   * Sinh option_slug duy nhất TRONG PHẠM VI 1 sản phẩm — giống cách
   * ProductVariantService xử lý variant_slug. Trước đây slug topping không
   * được đảm bảo duy nhất, nên 2 topping trùng tên trong cùng sản phẩm còn
   * bị trùng cả slug lẫn tên hiển thị.
   */
  async _generateUniqueOptionSlug(productId, baseSlug, excludeOptionId = null) {
    let slug = baseSlug;
    let suffix = 2;
    while (await productOptionRepository.existsByProductIdAndSlug(productId, slug, excludeOptionId)) {
      slug = `${baseSlug}-${suffix}`;
      suffix += 1;
    }
    return slug;
  }

  async addOption(shopId, productId, data) {
    const product = await productRepository.findByIdScoped(productId, shopId);
    if (!product) {
      throw new Error("Product not found");
    }

    const { optionName, extraPrice, status } = data;
    if (!optionName || !optionName.trim()) {
      throw new Error("Tên topping là bắt buộc");
    }
    const trimmedName = optionName.trim();
    if (await productOptionRepository.existsByProductIdAndName(productId, trimmedName)) {
      throw new Error("Sản phẩm đã có topping trùng tên này");
    }
    const parsedExtraPrice = extraPrice !== undefined && extraPrice !== "" ? parseFloat(extraPrice) : 0;
    if (isNaN(parsedExtraPrice) || parsedExtraPrice < 0) {
      throw new Error("Giá thêm phải lớn hơn hoặc bằng 0");
    }

    const baseSlug = toSlug(optionName) || `option-${Date.now()}`;
    const uniqueSlug = await this._generateUniqueOptionSlug(productId, baseSlug);

    return productOptionRepository.create({
      product_id: productId,
      option_name: trimmedName,
      option_slug: uniqueSlug,
      extra_price: parsedExtraPrice,
      status: status || "active"
    });
  }

  async editOption(shopId, productId, optionId, data) {
    const product = await productRepository.findByIdScoped(productId, shopId);
    if (!product) {
      throw new Error("Product not found");
    }

    const option = await productOptionRepository.findById(optionId);
    if (!option || String(option.product_id) !== String(productId)) {
      throw new Error("Option not found");
    }

    const { optionName, extraPrice, status } = data;
    const updateData = {};

    if (optionName && optionName.trim()) {
      const trimmedName = optionName.trim();
      if (await productOptionRepository.existsByProductIdAndName(productId, trimmedName, optionId)) {
        throw new Error("Sản phẩm đã có topping trùng tên này");
      }
      updateData.option_name = trimmedName;
      const baseSlug = toSlug(optionName) || option.option_slug;
      updateData.option_slug = await this._generateUniqueOptionSlug(productId, baseSlug, optionId);
    }
    if (extraPrice !== undefined && extraPrice !== "") {
      const parsedExtraPrice = parseFloat(extraPrice);
      if (isNaN(parsedExtraPrice) || parsedExtraPrice < 0) {
        throw new Error("Giá thêm phải lớn hơn hoặc bằng 0");
      }
      updateData.extra_price = parsedExtraPrice;
    }
    if (status) updateData.status = status;

    return productOptionRepository.update(optionId, updateData);
  }

  async deleteOption(shopId, productId, optionId) {
    const product = await productRepository.findByIdScoped(productId, shopId);
    if (!product) {
      throw new Error("Product not found");
    }

    const option = await productOptionRepository.findById(optionId);
    if (!option || String(option.product_id) !== String(productId)) {
      throw new Error("Option not found");
    }

    return productOptionRepository.softDelete(optionId);
  }
}

module.exports = new ProductOptionService();
