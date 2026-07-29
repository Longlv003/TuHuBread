const productRepository = require("../repositories/product.repository");
const productOptionRepository = require("../repositories/productOption.repository");
const { toSlug } = require("../utils/slug.util");

class ProductOptionService {
  async addOption(shopId, productId, data) {
    const product = await productRepository.findByIdScoped(productId, shopId);
    if (!product) {
      throw new Error("Product not found");
    }

    const { optionName, extraPrice, status } = data;
    if (!optionName) {
      throw new Error("Tên topping là bắt buộc");
    }
    const parsedExtraPrice = extraPrice !== undefined && extraPrice !== "" ? parseFloat(extraPrice) : 0;
    if (isNaN(parsedExtraPrice) || parsedExtraPrice < 0) {
      throw new Error("Giá thêm phải lớn hơn hoặc bằng 0");
    }

    return productOptionRepository.create({
      product_id: productId,
      option_name: optionName.trim(),
      option_slug: toSlug(optionName) || `option-${Date.now()}`,
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

    if (optionName) {
      updateData.option_name = optionName.trim();
      updateData.option_slug = toSlug(optionName) || option.option_slug;
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
