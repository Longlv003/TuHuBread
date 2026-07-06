const { globalCategoryModel } = require("../models/globalCategory.model");
const { shopCategoryModel } = require("../models/shopCategory.model");

// GET /api/categories
exports.getGlobalCategories = async (req, res) => {
  let dataRes = { msg: "OK", data: null };

  try {
    const categories = await globalCategoryModel.find({ status: "active" });

    // Trả về link ảnh tuyệt đối của danh mục
    dataRes.data = categories.map((category) => {
      // Lấy tên file ảnh từ path tương đối (ví dụ: /images/categories/cat_bread.jpg -> cat_bread.jpg)
      const fileName = category.category_icon ? category.category_icon.split("/").pop() : "default.jpg";
      return {
        ...category._doc,
        category_icon: `${req.protocol}://${req.get("host")}/images/categories/${fileName}`,
      };
    });
  } catch (err) {
    console.error("Get global categories error:", err.message);
    dataRes.msg = "Server error: " + err.message;
    return res.status(500).json(dataRes);
  }

  return res.json(dataRes);
};

// GET /api/shops/:shopId/categories
exports.getShopCategories = async (req, res) => {
  let dataRes = { msg: "OK", data: null };

  try {
    const { shopId } = req.params;
    const categories = await shopCategoryModel.find({
      shop_id: shopId,
      status: "active"
    }).sort({ sort_order: 1 });

    // Trả về link ảnh tuyệt đối của danh mục shop
    dataRes.data = categories.map((category) => {
      const fileName = category.category_icon ? category.category_icon.split("/").pop() : "default.jpg";
      return {
        ...category._doc,
        category_icon: `${req.protocol}://${req.get("host")}/images/categories/${fileName}`,
      };
    });
  } catch (err) {
    console.error("Get shop categories error:", err.message);
    dataRes.msg = "Server error: " + err.message;
    return res.status(500).json(dataRes);
  }

  return res.json(dataRes);
};
