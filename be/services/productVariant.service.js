const productRepository = require("../repositories/product.repository");
const productVariantRepository = require("../repositories/productVariant.repository");
const productBatchRepository = require("../repositories/productBatch.repository");
const { toSlug } = require("../utils/slug.util");

class ProductVariantService {
  async addVariant(shopId, productId, data) {
    const product = await productRepository.findByIdScoped(productId, shopId);
    if (!product) {
      throw new Error("Product not found");
    }

    const { variantName, price, salePrice, stockQuantity, status, image, expiredAt } = data;
    if (!variantName) {
      throw new Error("Tên biến thể là bắt buộc");
    }
    const parsedPrice = parseFloat(price);
    if (!price || isNaN(parsedPrice) || parsedPrice <= 0) {
      throw new Error("Giá biến thể phải lớn hơn 0");
    }

    const parsedStock = stockQuantity ? parseInt(stockQuantity) : 0;
    let expiredAtObj = null;
    if (parsedStock > 0 && expiredAt) {
      expiredAtObj = new Date(expiredAt);
      if (isNaN(expiredAtObj.getTime()) || expiredAtObj <= new Date()) {
        throw new Error("Hạn sử dụng phải sau ngày hôm nay");
      }
    }

    const variant = await productVariantRepository.create({
      product_id: productId,
      variant_name: variantName.trim(),
      variant_slug: toSlug(variantName) || `variant-${Date.now()}`,
      image: image || null,
      price: parsedPrice,
      sale_price: salePrice ? parseFloat(salePrice) : null,
      stock_quantity: parsedStock,
      status: status || "active"
    });

    if (expiredAtObj) {
      await productBatchRepository.create({
        product_id: productId,
        variant_id: variant._id,
        batch_code: `LOT-${Date.now()}`,
        quantity_imported: parsedStock,
        quantity_remaining: parsedStock,
        production_date: new Date(),
        expired_at: expiredAtObj,
        status: "active"
      });
    }

    return variant;
  }

  async editVariant(shopId, productId, variantId, data) {
    const product = await productRepository.findByIdScoped(productId, shopId);
    if (!product) {
      throw new Error("Product not found");
    }

    const variant = await productVariantRepository.findById(variantId);
    if (!variant || String(variant.product_id) !== String(productId)) {
      throw new Error("Variant not found");
    }

    const { variantName, price, salePrice, stockQuantity, status, image } = data;
    const updateData = {};

    if (variantName) {
      updateData.variant_name = variantName.trim();
      updateData.variant_slug = toSlug(variantName) || variant.variant_slug;
    }
    if (price !== undefined && price !== "") {
      const parsedPrice = parseFloat(price);
      if (isNaN(parsedPrice) || parsedPrice <= 0) {
        throw new Error("Giá biến thể phải lớn hơn 0");
      }
      updateData.price = parsedPrice;
    }
    if (salePrice !== undefined) updateData.sale_price = salePrice ? parseFloat(salePrice) : null;
    if (stockQuantity !== undefined) updateData.stock_quantity = parseInt(stockQuantity) || 0;
    if (status) updateData.status = status;
    if (image) updateData.image = image;

    return productVariantRepository.update(variantId, updateData);
  }

  async deleteVariant(shopId, productId, variantId) {
    const product = await productRepository.findByIdScoped(productId, shopId);
    if (!product) {
      throw new Error("Product not found");
    }

    const variant = await productVariantRepository.findById(variantId);
    if (!variant || String(variant.product_id) !== String(productId)) {
      throw new Error("Variant not found");
    }

    const activeCount = await productVariantRepository.countActiveByProductId(productId);
    if (activeCount <= 1) {
      throw new Error("Không thể xóa biến thể cuối cùng của sản phẩm");
    }

    return productVariantRepository.softDelete(variantId);
  }
}

module.exports = new ProductVariantService();
