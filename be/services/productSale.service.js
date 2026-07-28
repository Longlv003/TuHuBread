const productRepository = require("../repositories/product.repository");
const productVariantRepository = require("../repositories/productVariant.repository");
const productSaleRepository = require("../repositories/productSale.repository");

class ProductSaleService {
  async getSalesByShop(shopId) {
    const productIds = await productRepository.findIdsByShopId(shopId);
    return productSaleRepository.findByProductIds(productIds);
  }

  async getFormOptions(shopId) {
    const products = await productRepository.findByShopId(shopId);
    const productIds = products.map(p => p._id);
    const variants = await productVariantRepository.findByProductIds(productIds);

    const variantsByProduct = {};
    for (const v of variants) {
      const key = String(v.product_id);
      if (!variantsByProduct[key]) variantsByProduct[key] = [];
      variantsByProduct[key].push({ _id: String(v._id), variant_name: v.variant_name });
    }

    return { products, variantsByProduct };
  }

  async addSale(shopId, data) {
    const { productId, variantId, saleName, salePrice, saleLimit, startDate, endDate, status } = data;

    if (!productId || !saleName || !salePrice || !startDate || !endDate) {
      throw new Error("Sản phẩm, tên chương trình, giá khuyến mãi và thời gian là bắt buộc");
    }

    const product = await productRepository.findByIdScoped(productId, shopId);
    if (!product) {
      throw new Error("Product not found");
    }

    if (variantId) {
      const variant = await productVariantRepository.findById(variantId);
      if (!variant || String(variant.product_id) !== String(productId)) {
        throw new Error("Variant not found");
      }
    }

    const parsedSalePrice = parseFloat(salePrice);
    if (isNaN(parsedSalePrice) || parsedSalePrice <= 0) {
      throw new Error("Giá khuyến mãi phải lớn hơn 0");
    }

    const startDateObj = new Date(startDate);
    const endDateObj = new Date(endDate);
    if (endDateObj <= startDateObj) {
      throw new Error("Ngày kết thúc phải sau ngày bắt đầu");
    }

    return productSaleRepository.create({
      product_id: productId,
      variant_id: variantId || null,
      sale_name: saleName.trim(),
      sale_price: parsedSalePrice,
      sale_limit: saleLimit ? parseInt(saleLimit) : null,
      start_date: startDateObj,
      end_date: endDateObj,
      status: status || "active"
    });
  }

  async editSale(shopId, saleId, data) {
    const sale = await productSaleRepository.findByIdPopulated(saleId);
    if (!sale || String(sale.product_id.shop_id) !== String(shopId)) {
      throw new Error("Sale not found");
    }

    const { saleName, salePrice, saleLimit, startDate, endDate, status } = data;
    const updateData = {};

    if (saleName) updateData.sale_name = saleName.trim();
    if (salePrice !== undefined && salePrice !== "") {
      const parsed = parseFloat(salePrice);
      if (isNaN(parsed) || parsed <= 0) {
        throw new Error("Giá khuyến mãi phải lớn hơn 0");
      }
      updateData.sale_price = parsed;
    }
    if (saleLimit !== undefined) updateData.sale_limit = saleLimit ? parseInt(saleLimit) : null;
    if (startDate) updateData.start_date = new Date(startDate);
    if (endDate) updateData.end_date = new Date(endDate);
    if (status) updateData.status = status;

    if (updateData.start_date && updateData.end_date && updateData.end_date <= updateData.start_date) {
      throw new Error("Ngày kết thúc phải sau ngày bắt đầu");
    }

    return productSaleRepository.update(saleId, updateData);
  }

  async deleteSale(shopId, saleId) {
    const sale = await productSaleRepository.findByIdPopulated(saleId);
    if (!sale || String(sale.product_id.shop_id) !== String(shopId)) {
      throw new Error("Sale not found");
    }
    return productSaleRepository.softDelete(saleId);
  }
}

module.exports = new ProductSaleService();
