const bannerRepository = require("../repositories/banner.repository");

class BannerService {
  async getAllBanners() {
    return bannerRepository.findAll();
  }

  async getAllBannersPaginated(page = 1) {
    const parsedPage = Math.max(parseInt(page) || 1, 1);
    const limit = 10;
    const [banners, total] = await Promise.all([
      bannerRepository.findAllPaginated({ page: parsedPage, limit }),
      bannerRepository.countAll(),
    ]);
    return {
      banners,
      total,
      page: parsedPage,
      totalPages: Math.max(Math.ceil(total / limit), 1),
    };
  }

  async addBanner(data) {
    const { title, image, linkUrl, sortOrder, status, startDate, endDate } = data;

    if (!title || !image) {
      throw new Error("Tiêu đề và ảnh banner là bắt buộc");
    }

    let parsedSortOrder = sortOrder ? parseInt(sortOrder) : 0;
    if (parsedSortOrder === 0) {
      const maxSort = await bannerRepository.getMaxSortOrder();
      parsedSortOrder = maxSort + 1;
    }

    return bannerRepository.create({
      title: title.trim(),
      image,
      link_url: linkUrl || null,
      sort_order: parsedSortOrder,
      status: status || "active",
      start_date: startDate ? new Date(startDate) : null,
      end_date: endDate ? new Date(endDate) : null
    });
  }

  async updateBanner(id, data) {
    const existing = await bannerRepository.findById(id);
    if (!existing) {
      throw new Error("Banner not found");
    }

    const { title, image, linkUrl, sortOrder, status, startDate, endDate } = data;
    const updateData = {};

    if (title) updateData.title = title.trim();
    if (image) updateData.image = image;
    if (linkUrl !== undefined) updateData.link_url = linkUrl || null;
    if (sortOrder !== undefined) updateData.sort_order = parseInt(sortOrder) || 0;
    if (status) updateData.status = status;
    if (startDate !== undefined) updateData.start_date = startDate ? new Date(startDate) : null;
    if (endDate !== undefined) updateData.end_date = endDate ? new Date(endDate) : null;

    return bannerRepository.update(id, updateData);
  }

  async deleteBanner(id) {
    const existing = await bannerRepository.findById(id);
    if (!existing) {
      throw new Error("Banner not found");
    }
    return bannerRepository.softDelete(id);
  }
}

module.exports = new BannerService();
