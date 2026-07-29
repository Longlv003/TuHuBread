const bannerRepository = require("../repositories/banner.repository");

// GET /api/banners
exports.getActiveBanners = async (req, res) => {
  let dataRes = { msg: "OK", data: null };

  try {
    const banners = await bannerRepository.findAllActive();

    dataRes.data = banners.map((b) => ({
      _id: b._id,
      title: b.title,
      image: b.image.startsWith("http") ? b.image : `${req.protocol}://${req.get("host")}${b.image}`,
      link_url: b.link_url,
      sort_order: b.sort_order
    }));
  } catch (err) {
    console.error("Get active banners error:", err.message);
    dataRes.msg = "Server error: " + err.message;
    return res.status(500).json(dataRes);
  }

  return res.json(dataRes);
};
