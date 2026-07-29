const globalCategoryRepository = require("../repositories/globalCategory.repository");
const { toSlug } = require("../utils/slug.util");

class GlobalCategoryService {
  async getAllCategories() {
    return globalCategoryRepository.findAll();
  }

  async getAllCategoriesPaginated(page = 1) {
    const parsedPage = Math.max(parseInt(page) || 1, 1);
    const limit = 10;
    const [categories, total] = await Promise.all([
      globalCategoryRepository.findAllPaginated({ page: parsedPage, limit }),
      globalCategoryRepository.countAll(),
    ]);
    return {
      categories,
      total,
      page: parsedPage,
      totalPages: Math.max(Math.ceil(total / limit), 1),
    };
  }

  async addCategory(data) {
    const { categoryName, status, categoryIcon } = data;

    if (!categoryName) {
      throw new Error("Category Name is required");
    }

    const slug = toSlug(categoryName);
    if (!slug) {
      throw new Error("Tên danh mục không hợp lệ!");
    }

    const existingSlug = await globalCategoryRepository.findBySlug(slug);
    if (existingSlug) {
      throw new Error("Tên danh mục này đã tồn tại (trùng slug chuẩn hóa)!");
    }

    return globalCategoryRepository.create({
      category_name: categoryName.trim(),
      category_slug: slug,
      category_icon: categoryIcon || null,
      status: status || "active"
    });
  }

  async updateCategory(id, data) {
    const existing = await globalCategoryRepository.findById(id);
    if (!existing) {
      throw new Error("Category not found");
    }

    const { categoryName, status, categoryIcon } = data;
    const updateData = {};

    if (categoryName) {
      const slug = toSlug(categoryName);
      if (!slug) {
        throw new Error("Tên danh mục không hợp lệ!");
      }
      if (slug !== existing.category_slug) {
        const existingSlug = await globalCategoryRepository.findBySlug(slug);
        if (existingSlug) {
          throw new Error("Tên danh mục này đã tồn tại (trùng slug chuẩn hóa)!");
        }
      }
      updateData.category_name = categoryName.trim();
      updateData.category_slug = slug;
    }
    if (status) updateData.status = status;
    if (categoryIcon) updateData.category_icon = categoryIcon;

    return globalCategoryRepository.update(id, updateData);
  }

  async deleteCategory(id) {
    const existing = await globalCategoryRepository.findById(id);
    if (!existing) {
      throw new Error("Category not found");
    }
    return globalCategoryRepository.softDelete(id);
  }
}

module.exports = new GlobalCategoryService();
