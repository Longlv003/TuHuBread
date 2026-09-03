const bannerRepository = require("../repositories/banner.repository");
const {
  assertHttpUrl,
  parseNonNegativeNumber,
  parseOptionalDate,
  requireText,
} = require("../utils/validate.util");

/** Banner chỉ hiện trong khoảng thời gian đặt trước, nên ngày kết thúc trước
 * ngày bắt đầu là banner không bao giờ xuất hiện — rất khó lần ra nguyên nhân
 * nếu để lọt. */
function assertDateRange(startDate, endDate) {
  const start = parseOptionalDate(startDate, "Ngày bắt đầu");
  const end = parseOptionalDate(endDate, "Ngày kết thúc");
  if (start && end && end <= start) {
    throw new Error("Ngày kết thúc phải sau ngày bắt đầu");
  }
  return { start, end };
}

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

    if (!image) {
      throw new Error("Ảnh banner là bắt buộc");
    }
    const trimmedTitle = requireText(title, "Tiêu đề", { maxLength: 150 });
    const validLinkUrl = assertHttpUrl(linkUrl, "Đường dẫn banner");
    const { start, end } = assertDateRange(startDate, endDate);

    let parsedSortOrder = parseNonNegativeNumber(sortOrder, "Thứ tự hiển thị", { integer: true });
    if (parsedSortOrder === 0) {
      const maxSort = await bannerRepository.getMaxSortOrder();
      parsedSortOrder = maxSort + 1;
    }

    return bannerRepository.create({
      title: trimmedTitle,
      image,
      link_url: validLinkUrl,
      sort_order: parsedSortOrder,
      status: status || "active",
      start_date: start,
      end_date: end
    });
  }

  async updateBanner(id, data) {
    const existing = await bannerRepository.findById(id);
    if (!existing) {
      throw new Error("Banner not found");
    }

    const { title, image, linkUrl, sortOrder, status, startDate, endDate } = data;
    const updateData = {};

    if (title !== undefined) updateData.title = requireText(title, "Tiêu đề", { maxLength: 150 });
    if (image) updateData.image = image;
    if (linkUrl !== undefined) updateData.link_url = assertHttpUrl(linkUrl, "Đường dẫn banner");
    if (sortOrder !== undefined) {
      updateData.sort_order = parseNonNegativeNumber(sortOrder, "Thứ tự hiển thị", { integer: true });
    }
    if (status) updateData.status = status;
    if (startDate !== undefined) updateData.start_date = parseOptionalDate(startDate, "Ngày bắt đầu");
    if (endDate !== undefined) updateData.end_date = parseOptionalDate(endDate, "Ngày kết thúc");

    // So với giá trị đang lưu khi lần sửa này chỉ đổi một trong hai mốc, nếu
    // không thì sửa mỗi ngày kết thúc sẽ không có gì để đối chiếu.
    const finalStart = updateData.start_date !== undefined ? updateData.start_date : existing.start_date;
    const finalEnd = updateData.end_date !== undefined ? updateData.end_date : existing.end_date;
    if (finalStart && finalEnd && finalEnd <= finalStart) {
      throw new Error("Ngày kết thúc phải sau ngày bắt đầu");
    }

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
