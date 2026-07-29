const productRepository = require("../repositories/product.repository");
const productAttributeRepository = require("../repositories/productAttribute.repository");

class ProductAttributeService {
  async addAttribute(shopId, productId, data) {
    const product = await productRepository.findByIdScoped(productId, shopId);
    if (!product) {
      throw new Error("Product not found");
    }

    const { attributeKey, attributeLabel, attributeValue, sortOrder, status } = data;
    if (!attributeKey || !attributeLabel || !attributeValue) {
      throw new Error("Key, nhãn và giá trị thuộc tính là bắt buộc");
    }

    let parsedSortOrder = sortOrder ? parseInt(sortOrder) : 0;
    if (parsedSortOrder === 0) {
      const maxSort = await productAttributeRepository.getMaxSortOrder(productId);
      parsedSortOrder = maxSort + 1;
    }

    return productAttributeRepository.create({
      product_id: productId,
      attribute_key: attributeKey.trim(),
      attribute_label: attributeLabel.trim(),
      attribute_value: attributeValue.trim(),
      sort_order: parsedSortOrder,
      status: status || "active"
    });
  }

  async editAttribute(shopId, productId, attributeId, data) {
    const product = await productRepository.findByIdScoped(productId, shopId);
    if (!product) {
      throw new Error("Product not found");
    }

    const attribute = await productAttributeRepository.findById(attributeId);
    if (!attribute || String(attribute.product_id) !== String(productId)) {
      throw new Error("Attribute not found");
    }

    const { attributeKey, attributeLabel, attributeValue, sortOrder, status } = data;
    const updateData = {};

    if (attributeKey) updateData.attribute_key = attributeKey.trim();
    if (attributeLabel) updateData.attribute_label = attributeLabel.trim();
    if (attributeValue) updateData.attribute_value = attributeValue.trim();
    if (sortOrder !== undefined) updateData.sort_order = parseInt(sortOrder) || 0;
    if (status) updateData.status = status;

    return productAttributeRepository.update(attributeId, updateData);
  }

  async deleteAttribute(shopId, productId, attributeId) {
    const product = await productRepository.findByIdScoped(productId, shopId);
    if (!product) {
      throw new Error("Product not found");
    }

    const attribute = await productAttributeRepository.findById(attributeId);
    if (!attribute || String(attribute.product_id) !== String(productId)) {
      throw new Error("Attribute not found");
    }

    return productAttributeRepository.softDelete(attributeId);
  }
}

module.exports = new ProductAttributeService();
