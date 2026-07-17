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
}

module.exports = new ShopService();
