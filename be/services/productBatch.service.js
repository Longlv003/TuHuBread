const productRepository = require("../repositories/product.repository");
const productBatchRepository = require("../repositories/productBatch.repository");
const productVariantRepository = require("../repositories/productVariant.repository");

class ProductBatchService {
  async addBatch(shopId, productId, data) {
    const product = await productRepository.findByIdScoped(productId, shopId);
    if (!product) {
      throw new Error("Product not found");
    }

    const { variantId, batchCode, quantityImported, productionDate, expiredAt, status } = data;
    if (!batchCode || !quantityImported || !productionDate || !expiredAt) {
      throw new Error("Mã lô, số lượng nhập, ngày sản xuất và hạn sử dụng là bắt buộc");
    }

    const parsedQuantity = parseInt(quantityImported);
    if (isNaN(parsedQuantity) || parsedQuantity <= 0) {
      throw new Error("Số lượng nhập phải lớn hơn 0");
    }

    const productionDateObj = new Date(productionDate);
    const expiredAtObj = new Date(expiredAt);
    if (expiredAtObj <= productionDateObj) {
      throw new Error("Hạn sử dụng phải sau ngày sản xuất");
    }

    if (variantId) {
      const variant = await productVariantRepository.findById(variantId);
      if (!variant || String(variant.product_id) !== String(productId)) {
        throw new Error("Variant not found");
      }
    }

    return productBatchRepository.create({
      product_id: productId,
      variant_id: variantId || null,
      batch_code: batchCode.trim(),
      quantity_imported: parsedQuantity,
      quantity_remaining: parsedQuantity,
      production_date: productionDateObj,
      expired_at: expiredAtObj,
      status: status || "active"
    });
  }

  async editBatch(shopId, productId, batchId, data) {
    const product = await productRepository.findByIdScoped(productId, shopId);
    if (!product) {
      throw new Error("Product not found");
    }

    const batch = await productBatchRepository.findById(batchId);
    if (!batch || String(batch.product_id) !== String(productId)) {
      throw new Error("Batch not found");
    }

    const { quantityRemaining, status } = data;
    const updateData = {};

    if (quantityRemaining !== undefined && quantityRemaining !== "") {
      const parsed = parseInt(quantityRemaining);
      if (isNaN(parsed) || parsed < 0) {
        throw new Error("Số lượng còn lại không hợp lệ");
      }
      updateData.quantity_remaining = parsed;
    }
    if (status) updateData.status = status;

    return productBatchRepository.update(batchId, updateData);
  }

  async deleteBatch(shopId, productId, batchId) {
    const product = await productRepository.findByIdScoped(productId, shopId);
    if (!product) {
      throw new Error("Product not found");
    }

    const batch = await productBatchRepository.findById(batchId);
    if (!batch || String(batch.product_id) !== String(productId)) {
      throw new Error("Batch not found");
    }

    return productBatchRepository.softDelete(batchId);
  }
}

module.exports = new ProductBatchService();
