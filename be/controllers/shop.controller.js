const { shopModel } = require("../models/shop.model");
const { productModel } = require("../models/product.model");
const { userModel } = require("../models/user.model");
const { calculateDistanceKm } = require("../utils/distance.util");

// GET /api/shops?lat=&lng= — lat/lng tuỳ chọn: nếu có, trả kèm distance_km và
// sắp xếp shop gần nhất lên đầu (dùng để tìm cửa hàng gần vị trí khách hàng).
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

    const lat = parseFloat(req.query.lat);
    const lng = parseFloat(req.query.lng);
    const hasUserLocation = !isNaN(lat) && !isNaN(lng) && lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;

    // Trả về link ảnh tuyệt đối cho avatar và banner của cửa hàng
    let result = validShops.map((shop) => {
      const logoFile = shop.logo ? shop.logo.split("/").pop() : "default_avatar.jpg";
      const bannerFile = shop.banner ? shop.banner.split("/").pop() : "default_banner.jpg";

      const shopObj = { ...shop._doc };
      delete shopObj.avatar; // Đảm bảo loại bỏ avatar nếu lỡ có trong DB
      delete shopObj.owner_user_id; // Remove populated user info to avoid leak
      if (shopObj.total_reviews === 0) {
        // Chưa có đánh giá nào — trả về null thay vì số giả (99), để client tự
        // hiển thị "Chưa có đánh giá" thay vì hiểu nhầm thành rating thật.
        shopObj.rating_average = null;
      }

      if (hasUserLocation && shop.location && Array.isArray(shop.location.coordinates)) {
        shopObj.distance_km = Math.round(calculateDistanceKm([lng, lat], shop.location.coordinates) * 10) / 10;
      }

      return {
        ...shopObj,
        logo: `${req.protocol}://${req.get("host")}/images/shops/${logoFile}`,
        banner: `${req.protocol}://${req.get("host")}/images/shops/${bannerFile}`,
      };
    });

    if (hasUserLocation) {
      result = result.sort((a, b) => (a.distance_km ?? Infinity) - (b.distance_km ?? Infinity));
    }

    dataRes.data = result;

  } catch (err) {
    console.error("Get shops error:", err.message);
    dataRes.msg = "Server error: " + err.message;
    return res.status(500).json(dataRes);
  }

  return res.json(dataRes);
};
