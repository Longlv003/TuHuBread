const productRepository = require("../repositories/product.repository");
const productVariantRepository = require("../repositories/productVariant.repository");
const productOptionRepository = require("../repositories/productOption.repository");
const productBatchRepository = require("../repositories/productBatch.repository");
const { toSlug } = require("../utils/slug.util");

class ProductService {
  async getProductsByShop(shopId) {
    const products = await productRepository.findByShopId(shopId);
    const productIds = products.map(p => p._id);
    const variants = await productVariantRepository.findByProductIds(productIds);

    const firstVariantByProduct = new Map();
    for (const variant of variants) {
      const key = String(variant.product_id);
      if (!firstVariantByProduct.has(key)) {
        firstVariantByProduct.set(key, variant);
      }
    }

    return products.map(product => ({
      ...product.toObject(),
      display_variant: firstVariantByProduct.get(String(product._id)) || null
    }));
  }

  async getProductsByShopPaginated(shopId, page = 1) {
    const parsedPage = Math.max(parseInt(page) || 1, 1);
    const limit = 10;
    const [products, total] = await Promise.all([
      productRepository.findByShopIdPaginated(shopId, { page: parsedPage, limit }),
      productRepository.countByShopId(shopId),
    ]);

    const productIds = products.map(p => p._id);
    const variants = await productVariantRepository.findByProductIds(productIds);

    const firstVariantByProduct = new Map();
    for (const variant of variants) {
      const key = String(variant.product_id);
      if (!firstVariantByProduct.has(key)) {
        firstVariantByProduct.set(key, variant);
      }
    }

    return {
      products: products.map(product => ({
        ...product.toObject(),
        display_variant: firstVariantByProduct.get(String(product._id)) || null
      })),
      total,
      page: parsedPage,
      totalPages: Math.max(Math.ceil(total / limit), 1),
    };
  }

  async getProductDetail(shopId, productId) {
    const product = await productRepository.findByIdScoped(productId, shopId);
    if (!product) {
      throw new Error("Product not found");
    }

    const [variants, options, batches] = await Promise.all([
      productVariantRepository.findByProductId(productId),
      productOptionRepository.findByProductId(productId),
      productBatchRepository.findByProductId(productId)
    ]);

    return { product, variants, options, batches };
  }

  async addProduct(shopId, data) {
    const {
      globalCategoryId, productName, description, prepTimeMinutes, status,
      variantName, price, salePrice, stockQuantity, variantImage, expiredAt,
      isFeatured, isNew, storageNote
    } = data;

    if (!globalCategoryId || !productName) {
      throw new Error("Danh mục toàn hệ thống và tên sản phẩm là bắt buộc");
    }
    const parsedPrice = parseFloat(price);
    if (!price || isNaN(parsedPrice) || parsedPrice <= 0) {
      throw new Error("Giá sản phẩm phải lớn hơn 0");
    }

    const slug = toSlug(productName);
    if (!slug) {
      throw new Error("Tên sản phẩm không hợp lệ!");
    }

    const parsedStock = stockQuantity ? parseInt(stockQuantity) : 0;
    let expiredAtObj = null;
    if (parsedStock > 0 && expiredAt) {
      expiredAtObj = new Date(expiredAt);
      if (isNaN(expiredAtObj.getTime()) || expiredAtObj <= new Date()) {
        throw new Error("Hạn sử dụng phải sau ngày hôm nay");
      }
    }

    // Note: this MongoDB deployment is a standalone instance (no replica set), so
    // multi-document transactions aren't available here. Create sequentially and
    // roll back the product manually if the variant creation fails.
    const product = await productRepository.create({
      shop_id: shopId,
      global_category_id: globalCategoryId,
      product_name: productName.trim(),
      product_slug: slug,
      description: description || null,
      preparation_time_minutes: prepTimeMinutes ? parseInt(prepTimeMinutes) : 0,
      status: status || "active",
      is_featured: isFeatured === "on" || isFeatured === true,
      is_new: isNew === "on" || isNew === true,
      storage_note: storageNote || null
    });

    const finalVariantName = variantName && variantName.trim() ? variantName.trim() : "Mặc định";

    let variant = null;
    try {
      variant = await productVariantRepository.create({
        product_id: product._id,
        variant_name: finalVariantName,
        variant_slug: toSlug(finalVariantName) || "mac-dinh",
        image: variantImage || null,
        price: parsedPrice,
        sale_price: salePrice ? parseFloat(salePrice) : null,
        stock_quantity: parsedStock,
        status: "active"
      });

      if (expiredAtObj) {
        await productBatchRepository.create({
          product_id: product._id,
          variant_id: variant._id,
          batch_code: `LOT-${Date.now()}`,
          quantity_imported: parsedStock,
          quantity_remaining: parsedStock,
          production_date: new Date(),
          expired_at: expiredAtObj,
          status: "active"
        });
      }

      return { product, variant };
    } catch (err) {
      // Dọn dẹp đầy đủ những gì đã tạo được trước khi lỗi xảy ra — nếu chỉ xoá
      // product mà bỏ sót variant, sẽ để lại 1 product_variants mồ côi trỏ tới
      // product_id không còn tồn tại.
      if (variant) {
        await productVariantRepository.hardDelete(variant._id).catch(() => {});
      }
      await productRepository.hardDelete(product._id).catch(() => {});
      throw err;
    }
  }

  async updateProduct(shopId, productId, data) {
    const existing = await productRepository.findByIdScoped(productId, shopId);
    if (!existing) {
      throw new Error("Product not found");
    }

    const {
      productName, description, globalCategoryId, prepTimeMinutes, status,
      isFeatured, isNew, storageNote
    } = data;
    const updateData = {};

    if (productName) {
      const slug = toSlug(productName);
      if (!slug) {
        throw new Error("Tên sản phẩm không hợp lệ!");
      }
      updateData.product_name = productName.trim();
      updateData.product_slug = slug;
    }
    if (description !== undefined) updateData.description = description || null;
    if (globalCategoryId) updateData.global_category_id = globalCategoryId;
    if (prepTimeMinutes !== undefined) updateData.preparation_time_minutes = parseInt(prepTimeMinutes) || 0;
    if (status) updateData.status = status;
    if (isFeatured !== undefined) updateData.is_featured = isFeatured === "on" || isFeatured === true;
    if (isNew !== undefined) updateData.is_new = isNew === "on" || isNew === true;
    if (storageNote !== undefined) updateData.storage_note = storageNote || null;

    return productRepository.update(productId, updateData);
  }

  async deleteProduct(shopId, productId) {
    const existing = await productRepository.findByIdScoped(productId, shopId);
    if (!existing) {
      throw new Error("Product not found");
    }

    await productRepository.softDelete(productId);

    const [variants, options, batches] = await Promise.all([
      productVariantRepository.findByProductId(productId),
      productOptionRepository.findByProductId(productId),
      productBatchRepository.findByProductId(productId)
    ]);

    await Promise.all([
      ...variants.map(v => productVariantRepository.softDelete(v._id)),
      ...options.map(o => productOptionRepository.softDelete(o._id)),
      ...batches.map(b => productBatchRepository.softDelete(b._id))
    ]);

    return true;
  }
}

module.exports = new ProductService();
