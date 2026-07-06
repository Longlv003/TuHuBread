const { shopModel } = require("../models/shop.model");

// GET /api/shops
exports.getShops = async (req, res) => {
  let dataRes = { msg: "OK", data: null };

  try {
    const shops = await shopModel.find({ status: "active" });

    // Trả về link ảnh tuyệt đối cho avatar và banner của cửa hàng
    dataRes.data = shops.map((shop) => {
      const logoFile = shop.logo ? shop.logo.split("/").pop() : "default_avatar.jpg";
      const bannerFile = shop.banner ? shop.banner.split("/").pop() : "default_banner.jpg";
      
      const shopObj = { ...shop._doc };
      delete shopObj.avatar; // Đảm bảo loại bỏ avatar nếu lỡ có trong DB
      
      return {
        ...shopObj,
        logo: `${req.protocol}://${req.get("host")}/images/shops/${logoFile}`,
        banner: `${req.protocol}://${req.get("host")}/images/shops/${bannerFile}`,
      };
    });

  } catch (err) {
    console.error("Get shops error:", err.message);
    dataRes.msg = "Server error: " + err.message;
    return res.status(500).json(dataRes);
  }

  return res.json(dataRes);
};
