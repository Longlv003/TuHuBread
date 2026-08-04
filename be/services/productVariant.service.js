const productRepository = require("../repositories/product.repository");
const productVariantRepository = require("../repositories/productVariant.repository");
const productBatchRepository = require("../repositories/productBatch.repository");
const { toSlug } = require("../utils/slug.util");

class ProductVariantService {
  /**
   * Sinh variant_slug duy nhất TRONG PHẠM VI 1 sản phẩm — 2 biến thể tên
   * giống nhau (vd. cùng "Size L" ở 2 sản phẩm khác nhau, hoặc lỡ đặt trùng
   * tên trong cùng sản phẩm) trước đây sinh ra cùng 1 slug không phân biệt.
   * Thêm hậu tố -2, -3... khi phát hiện trùng trong cùng sản phẩm.
   */
  async _generateUniqueVariantSlug(productId, baseSlug, excludeVariantId = null) {
    let slug = baseSlug;
    let suffix = 2;
    while (await productVariantRepository.existsByProductIdAndSlug(productId, slug, excludeVariantId)) {
      slug = `${baseSlug}-${suffix}`;
      suffix += 1;
    }
    return slug;
  }

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

    const baseSlug = toSlug(variantName) || `variant-${Date.now()}`;
    const uniqueSlug = await this._generateUniqueVariantSlug(productId, baseSlug);

    const variant = await productVariantRepository.create({
      product_id: productId,
      variant_name: variantName.trim(),
      variant_slug: uniqueSlug,
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

    const { variantName, price, salePrice, stockQuantity, status, image, expiredAt } = data;
    const updateData = {};

    if (variantName) {
      updateData.variant_name = variantName.trim();
      const baseSlug = toSlug(variantName) || variant.variant_slug;
      updateData.variant_slug = await this._generateUniqueVariantSlug(productId, baseSlug, variantId);
    }
    if (price !== undefined && price !== "") {
      const parsedPrice = parseFloat(price);
      if (isNaN(parsedPrice) || parsedPrice <= 0) {
        throw new Error("Giá biến thể phải lớn hơn 0");
      }
      updateData.price = parsedPrice;
    }
    if (salePrice !== undefined) updateData.sale_price = salePrice ? parseFloat(salePrice) : null;

    let parsedStock;
    if (stockQuantity !== undefined) {
      parsedStock = parseInt(stockQuantity) || 0;
      updateData.stock_quantity = parsedStock;
    }
    if (status) updateData.status = status;
    if (image) updateData.image = image;

    // Nhập thêm hạn sử dụng khi sửa — ghi nhận thành 1 lô hàng mới, chỉ khi
    // lần sửa này thực sự có nhập số lượng kèm HSD.
    if (parsedStock > 0 && expiredAt) {
      const expiredAtObj = new Date(expiredAt);
      if (isNaN(expiredAtObj.getTime()) || expiredAtObj <= new Date()) {
        throw new Error("Hạn sử dụng phải sau ngày hôm nay");
      }
      await productBatchRepository.create({
        product_id: productId,
        variant_id: variantId,
        batch_code: `LOT-${Date.now()}`,
        quantity_imported: parsedStock,
        quantity_remaining: parsedStock,
        production_date: new Date(),
        expired_at: expiredAtObj,
        status: "active"
      });
    }

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
