const shopCategoryRepository = require("../repositories/shopCategory.repository");

/**
 * Clean and convert Vietnamese string to standard slug
 * @param {string} str
 */
function toSlug(str) {
  if (!str) return "";
  return str
    .toLowerCase()
    .normalize('NFD') // Separate base characters and diacritics
    .replace(/[\u0300-\u036f]/g, '') // Remove diacritics
    .replace(/[đĐ]/g, 'd')
    .trim()
    .replace(/[^a-z0-9 -]/g, '') // Remove special characters
    .replace(/\s+/g, '-') // Replace spaces with -
    .replace(/-+/g, '-'); // Replace multiple - with single -
}

class ShopCategoryService {
  /**
   * Get all active categories for a shop
   * @param {string} shopId
   */
  async getCategoriesByShop(shopId) {
    if (!shopId) {
      throw new Error("Shop ID is required");
    }
    return shopCategoryRepository.findByShopId(shopId);
  }

  /**
   * Add a new category
   * @param {string} shopId
   * @param {object} categoryData
   */
  async addCategory(shopId, categoryData) {
    const { categoryName, sortOrder, status, categoryIcon } = categoryData;

    if (!categoryName) {
      throw new Error("Category Name is required");
    }

    // Generate clean slug
    const slug = toSlug(categoryName);
    if (!slug) {
      throw new Error("Tên danh mục không hợp lệ!");
    }

    // Check duplicate slug for this shop
    const existingSlug = await shopCategoryRepository.findBySlugAndShopId(slug, shopId);
    if (existingSlug) {
      throw new Error("Tên danh mục này đã tồn tại trong cửa hàng của bạn (trùng slug chuẩn hóa)!");
    }

    let parsedSortOrder = sortOrder ? parseInt(sortOrder) : 0;
    if (parsedSortOrder < 0) {
      throw new Error("Thứ tự hiển thị phải lớn hơn hoặc bằng 0!");
    }

    // Auto-increment sort_order if it is 0 (or not specified) to place it at the end
    if (parsedSortOrder === 0) {
      const maxSort = await shopCategoryRepository.getMaxSortOrder(shopId);
      parsedSortOrder = maxSort + 1;
    }

    return shopCategoryRepository.create({
      shop_id: shopId,
      category_name: categoryName.trim(),
      category_slug: slug,
      category_icon: categoryIcon,
      sort_order: parsedSortOrder,
      status: status || "active"
    });
  }

  /**
   * Update category information
   * @param {string} id
   * @param {object} categoryData
   */
  async updateCategory(id, categoryData) {
    const { categoryName, sortOrder, status, categoryIcon } = categoryData;
    const existing = await shopCategoryRepository.findById(id);
    if (!existing) {
      throw new Error("Category not found");
    }

    const updateData = {};
    if (categoryName) {
      const slug = toSlug(categoryName);
      if (!slug) {
        throw new Error("Tên danh mục không hợp lệ!");
      }

      // Check duplicate slug for this shop if slug has changed
      if (slug !== existing.category_slug) {
        const existingSlug = await shopCategoryRepository.findBySlugAndShopId(slug, existing.shop_id);
        if (existingSlug) {
          throw new Error("Tên danh mục này đã tồn tại trong cửa hàng của bạn (trùng slug chuẩn hóa)!");
        }
      }

      updateData.category_name = categoryName.trim();
      updateData.category_slug = slug;
    }

    if (sortOrder !== undefined) {
      const parsedSortOrder = parseInt(sortOrder);
      if (parsedSortOrder < 0) {
        throw new Error("Thứ tự hiển thị phải lớn hơn hoặc bằng 0!");
      }
      updateData.sort_order = parsedSortOrder;
    }
    if (status) {
      updateData.status = status;
    }
    if (categoryIcon) {
      updateData.category_icon = categoryIcon;
    }

    return shopCategoryRepository.update(id, updateData);
  }

  /**
   * Soft delete a category
   * @param {string} id
   */
  async deleteCategory(id) {
    const existing = await shopCategoryRepository.findById(id);
    if (!existing) {
      throw new Error("Category not found");
    }
    return shopCategoryRepository.softDelete(id);
  }
}

module.exports = new ShopCategoryService();
