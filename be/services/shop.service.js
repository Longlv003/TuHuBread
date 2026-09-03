const shopRepository = require("../repositories/shop.repository");
const { normalizePhone, requireText, parseCoordinates } = require("../utils/validate.util");

class ShopService {
  /**
   * Update shop logo path
   * @param {string} shopId
   * @param {string} logoPath
   */
  async updateLogo(shopId, logoPath) {
    if (!shopId || !logoPath) {
      throw new Error("Shop ID and Logo Path are required");
    }
    return shopRepository.update(shopId, { logo: logoPath });
  }

  /**
   * Update shop profile information
   * @param {string} shopId
   * @param {object} data
   */
  async updateProfile(shopId, data) {
    const { shopName, phoneNumber, address, openTime, closeTime, latitude, longitude } = data;

    const trimmedShopName = requireText(shopName, "Tên cửa hàng", { maxLength: 120 });
    const trimmedAddress = requireText(address, "Địa chỉ", { maxLength: 255 });
    const normalizedPhone = normalizePhone(phoneNumber);

    const timeRegex = /^([01]\d|2[0-3]):[0-5]\d$/;
    if (openTime && !timeRegex.test(openTime)) {
      throw new Error("Giờ mở cửa không hợp lệ (định dạng HH:mm)");
    }
    if (closeTime && !timeRegex.test(closeTime)) {
      throw new Error("Giờ đóng cửa không hợp lệ (định dạng HH:mm)");
    }

    const updateData = {
      shop_name: trimmedShopName,
      phone_number: normalizedPhone,
      address: trimmedAddress,
      open_time: openTime || null,
      close_time: closeTime || null
    };

    // Vị trí trên bản đồ — tuỳ chọn, chỉ cập nhật nếu chủ shop có ghim lại vị trí mới.
    if (latitude !== undefined && longitude !== undefined && latitude !== "" && longitude !== "") {
      const coords = parseCoordinates(latitude, longitude);
      updateData.location = {
        type: "Point",
        coordinates: [coords.longitude, coords.latitude]
      };
    }

    return shopRepository.update(shopId, updateData);
  }

  /**
   * Toggle shop open/closed status
   * @param {string} shopId
   * @param {boolean} isOpen
   */
  async toggleOpenStatus(shopId, isOpen) {
    return shopRepository.update(shopId, { is_open: !!isOpen });
  }

  /**
   * Update shop banner image path
   * @param {string} shopId
   * @param {string} bannerPath
   */
  async updateBanner(shopId, bannerPath) {
    if (!shopId || !bannerPath) {
      throw new Error("Shop ID and Banner Path are required");
    }
    return shopRepository.update(shopId, { banner: bannerPath });
  }

  // --- Admin: manage all shops/branches ---

  async getAllShops() {
    return shopRepository.findAll();
  }

  async getAllShopsPaginated(page = 1) {
    const parsedPage = Math.max(parseInt(page) || 1, 1);
    const limit = 10;
    const [shops, total] = await Promise.all([
      shopRepository.findAllPaginated({ page: parsedPage, limit }),
      shopRepository.countAll(),
    ]);
    return {
      shops,
      total,
      page: parsedPage,
      totalPages: Math.max(Math.ceil(total / limit), 1),
    };
  }

  /**
   * Admin: update any shop's info directly by ID
   * @param {string} shopId
   * @param {object} data
   */
  async adminUpdateShop(shopId, data) {
    const existing = await shopRepository.findById(shopId);
    if (!existing) {
      throw new Error("Shop not found");
    }

    const { shopName, phoneNumber, address, latitude, longitude, openTime, closeTime } = data;
    const updateData = {};

    if (shopName) updateData.shop_name = requireText(shopName, "Tên cửa hàng", { maxLength: 120 });
    if (phoneNumber) updateData.phone_number = normalizePhone(phoneNumber);
    if (address) updateData.address = requireText(address, "Địa chỉ", { maxLength: 255 });
    if (latitude !== undefined && longitude !== undefined && latitude !== "" && longitude !== "") {
      const coords = parseCoordinates(latitude, longitude);
      updateData.location = {
        type: "Point",
        coordinates: [coords.longitude, coords.latitude]
      };
    }

    const timeRegex = /^([01]\d|2[0-3]):[0-5]\d$/;
    if (openTime !== undefined) {
      if (openTime && !timeRegex.test(openTime)) {
        throw new Error("Giờ mở cửa không hợp lệ (định dạng HH:mm)");
      }
      updateData.open_time = openTime || null;
    }
    if (closeTime !== undefined) {
      if (closeTime && !timeRegex.test(closeTime)) {
        throw new Error("Giờ đóng cửa không hợp lệ (định dạng HH:mm)");
      }
      updateData.close_time = closeTime || null;
    }

    return shopRepository.update(shopId, updateData);
  }
}

module.exports = new ShopService();
