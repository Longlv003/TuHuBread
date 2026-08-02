const { shopModel } = require("../models/shop.model");
const { productModel } = require("../models/product.model");
const { userModel } = require("../models/user.model");

// GET /api/shops
exports.getShops = async (req, res) => {
  let dataRes = { msg: "OK", data: null };

  try {
    const activeProductShopIds = await productModel.distinct("shop_id", { status: "active", deleted_at: null });

    const shops = await shopModel.find({
      _id: { $in: activeProductShopIds },
      status: "active",
      deleted_at: null
    }).populate("owner_user_id");

    const validShops = shops.filter(shop => {
      const owner = shop.owner_user_id;
      return owner && owner.status !== "blocked" && owner.deleted_at === null;
    });

    // Trả về link ảnh tuyệt đối cho avatar và banner của cửa hàng
    dataRes.data = validShops.map((shop) => {
      const logoFile = shop.logo ? shop.logo.split("/").pop() : "default_avatar.jpg";
      const bannerFile = shop.banner ? shop.banner.split("/").pop() : "default_banner.jpg";
      
      const shopObj = { ...shop._doc };
      delete shopObj.avatar; // Đảm bảo loại bỏ avatar nếu lỡ có trong DB
      delete shopObj.owner_user_id; // Remove populated user info to avoid leak
      if (shopObj.total_reviews === 0) {
        shopObj.rating_average = 99;
      }
      
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
