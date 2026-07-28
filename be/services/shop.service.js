const shopRepository = require("../repositories/shop.repository");

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
    const { shopName, phoneNumber, address, openTime, closeTime } = data;

    if (!shopName || !phoneNumber || !address) {
      throw new Error("Tên cửa hàng, số điện thoại và địa chỉ là bắt buộc");
    }

    const timeRegex = /^([01]\d|2[0-3]):[0-5]\d$/;
    if (openTime && !timeRegex.test(openTime)) {
      throw new Error("Giờ mở cửa không hợp lệ (định dạng HH:mm)");
    }
    if (closeTime && !timeRegex.test(closeTime)) {
      throw new Error("Giờ đóng cửa không hợp lệ (định dạng HH:mm)");
    }

    return shopRepository.update(shopId, {
      shop_name: shopName.trim(),
      phone_number: phoneNumber.trim(),
      address: address.trim(),
      open_time: openTime || null,
      close_time: closeTime || null
    });
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

    if (shopName) updateData.shop_name = shopName.trim();
    if (phoneNumber) updateData.phone_number = phoneNumber.trim();
    if (address) updateData.address = address.trim();
    if (latitude !== undefined && longitude !== undefined && latitude !== "" && longitude !== "") {
      updateData.location = {
        type: "Point",
        coordinates: [parseFloat(longitude), parseFloat(latitude)]
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
