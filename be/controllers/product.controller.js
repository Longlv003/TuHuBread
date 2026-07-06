const { productModel } = require("../models/product.model");
const mongoose = require("mongoose");

// GET /api/products
exports.getProducts = async (req, res) => {
  let dataRes = { msg: "OK", data: null };

  try {
    const { shop_id, global_category_id, shop_category_id, search } = req.query;

    const matchStage = { status: "active" };

    if (shop_id) {
      matchStage.shop_id = new mongoose.Types.ObjectId(shop_id);
    }
    if (global_category_id && global_category_id !== "all") {
      matchStage.global_category_id = new mongoose.Types.ObjectId(global_category_id);
    }
    if (shop_category_id && shop_category_id !== "all") {
      matchStage.shop_category_id = new mongoose.Types.ObjectId(shop_category_id);
    }
    if (search) {
      matchStage.product_name = { $regex: search, $options: "i" };
    }

    const now = new Date();

    const products = await productModel.aggregate([
      { $match: matchStage },
      {
        $lookup: {
          from: "product_variants",
          localField: "_id",
          foreignField: "product_id",
          as: "variants",
        }
      },
      {
        $lookup: {
          from: "product_sales",
          let: { prodId: "$_id" },
          pipeline: [
            {
              $match: {
                $expr: {
                  $and: [
                    { $eq: ["$product_id", "$$prodId"] },
                    { $eq: ["$status", "active"] },
                    { $lt: ["$start_date", now] },
                    { $gt: ["$end_date", now] }
                  ]
                }
              }
            }
          ],
          as: "active_sales"
        }
      },
      {
        $project: {
          _id: 1,
          shop_id: 1,
          global_category_id: 1,
          shop_category_id: 1,
          product_name: 1,
          product_slug: 1,
          description: 1,
          preparation_time_minutes: 1,
          status: 1,
          rating: { $literal: 5.0 },
          sales_count: { $literal: 100 },
          price: {
            $ifNull: [
              { $arrayElemAt: ["$variants.price", 0] },
              0
            ]
          },
          image: {
            $ifNull: [
              { $arrayElemAt: ["$variants.image", 0] },
              "/images/products/prod_special.jpg"
            ]
          },
          active_sale: {
            $cond: {
              if: { $gt: [{ $size: "$active_sales" }, 0] },
              then: { $arrayElemAt: ["$active_sales", 0] },
              else: null
            }
          }
        }
      }
    ]);

    // Trả về link ảnh tuyệt đối của sản phẩm
    dataRes.data = products.map((product) => {
      const fileName = product.image ? product.image.split("/").pop() : "prod_special.jpg";
      return {
        ...product,
        image: `${req.protocol}://${req.get("host")}/images/products/${fileName}`,
      };
    });

  } catch (err) {
    console.error("Get products error:", err.message);
    dataRes.msg = "Server error: " + err.message;
    return res.status(500).json(dataRes);
  }

  return res.json(dataRes);
};

// GET /api/products/best-sellers
exports.getBestSellers = async (req, res) => {
  let dataRes = { msg: "OK", data: null };

  try {
    const { shop_id } = req.query;
    const matchStage = { status: "active" };
    if (shop_id) {
      matchStage.shop_id = new mongoose.Types.ObjectId(shop_id);
    }

    const now = new Date();

    const products = await productModel.aggregate([
      { $match: matchStage },
      {
        $lookup: {
          from: "product_variants",
          localField: "_id",
          foreignField: "product_id",
          as: "variants",
        }
      },
      {
        $lookup: {
          from: "product_sales",
          let: { prodId: "$_id" },
          pipeline: [
            {
              $match: {
                $expr: {
                  $and: [
                    { $eq: ["$product_id", "$$prodId"] },
                    { $eq: ["$status", "active"] },
                    { $lt: ["$start_date", now] },
                    { $gt: ["$end_date", now] }
                  ]
                }
              }
            }
          ],
          as: "active_sales"
        }
      },
      {
        $project: {
          _id: 1,
          shop_id: 1,
          global_category_id: 1,
          shop_category_id: 1,
          product_name: 1,
          product_slug: 1,
          description: 1,
          preparation_time_minutes: 1,
          status: 1,
          rating: { $literal: 5.0 },
          // Ở đây ta cộng dồn số lượng đã bán từ tất cả các variant làm doanh số thực tế
          sales_count: { $sum: "$variants.sold_quantity" },
          price: {
            $ifNull: [
              { $arrayElemAt: ["$variants.price", 0] },
              0
            ]
          },
          image: {
            $ifNull: [
              { $arrayElemAt: ["$variants.image", 0] },
              "/images/products/prod_special.jpg"
            ]
          },
          active_sale: {
            $cond: {
              if: { $gt: [{ $size: "$active_sales" }, 0] },
              then: { $arrayElemAt: ["$active_sales", 0] },
              else: null
            }
          }
        }
      },
      // Sắp xếp giảm dần theo số lượng bán ra
      { $sort: { sales_count: -1 } },
      { $limit: 4 }
    ]);

    dataRes.data = products.map((product) => {
      const fileName = product.image ? product.image.split("/").pop() : "prod_special.jpg";
      return {
        ...product,
        image: `${req.protocol}://${req.get("host")}/images/products/${fileName}`,
      };
    });

  } catch (err) {
    console.error("Get best sellers error:", err.message);
    dataRes.msg = "Server error: " + err.message;
    return res.status(500).json(dataRes);
  }

  return res.json(dataRes);
};

// GET /api/products/sales
exports.getSaleProducts = async (req, res) => {
  let dataRes = { msg: "OK", data: null };

  try {
    const { shop_id } = req.query;
    const matchStage = { status: "active" };
    if (shop_id) {
      matchStage.shop_id = new mongoose.Types.ObjectId(shop_id);
    }

    const now = new Date();

    const products = await productModel.aggregate([
      { $match: matchStage },
      {
        $lookup: {
          from: "product_variants",
          localField: "_id",
          foreignField: "product_id",
          as: "variants",
        }
      },
      {
        $lookup: {
          from: "product_sales",
          let: { prodId: "$_id" },
          pipeline: [
            {
              $match: {
                $expr: {
                  $and: [
                    { $eq: ["$product_id", "$$prodId"] },
                    { $eq: ["$status", "active"] },
                    { $lt: ["$start_date", now] },
                    { $gt: ["$end_date", now] }
                  ]
                }
              }
            }
          ],
          as: "active_sales"
        }
      },
      {
        $project: {
          _id: 1,
          shop_id: 1,
          global_category_id: 1,
          shop_category_id: 1,
          product_name: 1,
          product_slug: 1,
          description: 1,
          preparation_time_minutes: 1,
          status: 1,
          rating: { $literal: 4.9 },
          sales_count: { $sum: "$variants.sold_quantity" },
          price: {
            $ifNull: [
              { $arrayElemAt: ["$variants.price", 0] },
              0
            ]
          },
          image: {
            $ifNull: [
              { $arrayElemAt: ["$variants.image", 0] },
              "/images/products/prod_special.jpg"
            ]
          },
          active_sale: {
            $cond: {
              if: { $gt: [{ $size: "$active_sales" }, 0] },
              then: { $arrayElemAt: ["$active_sales", 0] },
              else: null
            }
          }
        }
      },
      // CHỈ lọc các sản phẩm có chương trình sale đang active thực tế
      { $match: { active_sale: { $ne: null } } }
    ]);

    dataRes.data = products.map((product) => {
      const fileName = product.image ? product.image.split("/").pop() : "prod_special.jpg";
      return {
        ...product,
        image: `${req.protocol}://${req.get("host")}/images/products/${fileName}`,
      };
    });

  } catch (err) {
    console.error("Get sale products error:", err.message);
    dataRes.msg = "Server error: " + err.message;
    return res.status(500).json(dataRes);
  }

  return res.json(dataRes);
};
