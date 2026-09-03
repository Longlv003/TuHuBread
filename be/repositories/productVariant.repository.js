const mongoose = require("mongoose");
const { productVariantModel } = require("../models/productVariant.model");

class ProductVariantRepository {
  async findById(id) {
    return productVariantModel.findById(id);
  }

  async findByProductId(productId) {
    return productVariantModel.find({ product_id: productId, deleted_at: null }).sort({ createdAt: 1 });
  }

  async findByProductIds(productIds) {
    return productVariantModel.find({ product_id: { $in: productIds }, deleted_at: null }).sort({ createdAt: 1 });
  }

  async countActiveByProductId(productId) {
    return productVariantModel.countDocuments({ product_id: productId, status: { $ne: "inactive" }, deleted_at: null });
  }

  async existsByProductIdAndSlug(productId, slug, excludeVariantId) {
    const query = { product_id: productId, variant_slug: slug, deleted_at: null };
    if (excludeVariantId) {
      query._id = { $ne: excludeVariantId };
    }
    const doc = await productVariantModel.findOne(query).select("_id");
    return !!doc;
  }

  /**
   * Kiểm tra trùng TÊN biến thể (không phân biệt hoa/thường, đã trim) trong
   * cùng 1 sản phẩm — khác với existsByProductIdAndSlug vốn chỉ đảm bảo slug
   * (định danh nội bộ) là duy nhất chứ không ngăn 2 biến thể hiển thị cùng
   * tên "M" gây nhầm lẫn cho cả chủ shop lẫn khách hàng khi chọn mua.
   */
  async existsByProductIdAndName(productId, variantName, excludeVariantId) {
    const escaped = variantName.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const query = {
      product_id: productId,
      variant_name: { $regex: `^${escaped}$`, $options: "i" },
      deleted_at: null,
    };
    if (excludeVariantId) {
      query._id = { $ne: excludeVariantId };
    }
    const doc = await productVariantModel.findOne(query).select("_id");
    return !!doc;
  }

  /**
   * Biến thể còn đang bán mà tồn kho đã xuống dưới ngưỡng — nguồn cho cảnh báo
   * "sản phẩm sắp hết" ở Dashboard.
   *
   * Lọc theo shop phải đi vòng qua bảng products vì productVariant không giữ
   * shop_id; `$lookup` rồi `$match` đúng shop trước khi trả về.
   */
  async findLowStockByShopId(shopId, { threshold = 5, limit = 5 } = {}) {
    return productVariantModel.aggregate([
      {
        $match: {
          deleted_at: null,
          status: "active",
          stock_quantity: { $lte: threshold },
        },
      },
      {
        $lookup: {
          from: "products",
          localField: "product_id",
          foreignField: "_id",
          as: "product",
        },
      },
      { $unwind: "$product" },
      {
        $match: {
          "product.shop_id": new mongoose.Types.ObjectId(String(shopId)),
          "product.deleted_at": null,
          "product.status": "active",
        },
      },
      { $sort: { stock_quantity: 1 } },
      {
        $project: {
          _id: 1,
          variant_name: 1,
          stock_quantity: 1,
          product_id: "$product._id",
          product_name: "$product.product_name",
        },
      },
      { $limit: limit },
    ]);
  }

  async create(data) {
    return productVariantModel.create(data);
  }

  async update(id, updateData) {
    return productVariantModel.findByIdAndUpdate(id, updateData, { new: true, runValidators: true });
  }

  async softDelete(id) {
    return productVariantModel.findByIdAndUpdate(id, { deleted_at: new Date(), status: "inactive" }, { new: true, runValidators: true });
  }

  async hardDelete(id) {
    return productVariantModel.findByIdAndDelete(id);
  }
}

module.exports = new ProductVariantRepository();
