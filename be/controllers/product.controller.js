const { productModel } = require("../models/product.model");
const { productVariantModel } = require("../models/productVariant.model");
const { productOptionModel } = require("../models/productOption.model");
const { productAttributeModel } = require("../models/productAttribute.model");
const { productSaleModel } = require("../models/productSale.model");
const { shopModel } = require("../models/shop.model");
const { reviewModel } = require("../models/review.model");
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
        $lookup: {
          from: "reviews",
          localField: "_id",
          foreignField: "product_id",
          as: "db_reviews",
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
          rating: {
            $cond: {
              if: { $gt: [{ $size: { $filter: { input: "$db_reviews", as: "r", cond: { $eq: ["$$r.status", "visible"] } } } }, 0] },
              then: {
                $round: [
                  {
                    $avg: {
                      $map: {
                        input: { $filter: { input: "$db_reviews", as: "r", cond: { $eq: ["$$r.status", "visible"] } } },
                        as: "rev",
                        in: "$$rev.rating"
                      }
                    }
                  },
                  1
                ]
              },
              else: 0.0
            }
          },
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
        $lookup: {
          from: "reviews",
          localField: "_id",
          foreignField: "product_id",
          as: "db_reviews",
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
          rating: {
            $cond: {
              if: { $gt: [{ $size: { $filter: { input: "$db_reviews", as: "r", cond: { $eq: ["$$r.status", "visible"] } } } }, 0] },
              then: {
                $round: [
                  {
                    $avg: {
                      $map: {
                        input: { $filter: { input: "$db_reviews", as: "r", cond: { $eq: ["$$r.status", "visible"] } } },
                        as: "rev",
                        in: "$$rev.rating"
                      }
                    }
                  },
                  1
                ]
              },
              else: 0.0
            }
          },
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
        $lookup: {
          from: "reviews",
          localField: "_id",
          foreignField: "product_id",
          as: "db_reviews",
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
          rating: {
            $cond: {
              if: { $gt: [{ $size: { $filter: { input: "$db_reviews", as: "r", cond: { $eq: ["$$r.status", "visible"] } } } }, 0] },
              then: {
                $round: [
                  {
                    $avg: {
                      $map: {
                        input: { $filter: { input: "$db_reviews", as: "r", cond: { $eq: ["$$r.status", "visible"] } } },
                        as: "rev",
                        in: "$$rev.rating"
                      }
                    }
                  },
                  1
                ]
              },
              else: 0.0
            }
          },
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

// GET /api/products/:id
exports.getProductDetail = async (req, res) => {
  let dataRes = { msg: "OK", data: null };

  try {
    const { id } = req.params;
    if (!mongoose.Types.ObjectId.isValid(id)) {
      dataRes.msg = "Invalid Product ID";
      return res.status(400).json(dataRes);
    }

    const product = await productModel.findOne({ _id: id, status: "active" });
    if (!product) {
      dataRes.msg = "Product not found";
      return res.status(404).json(dataRes);
    }

    const now = new Date();

    // Query các dữ liệu liên quan song song
    const [variants, options, attributes, activeSales, shop, dbReviews] = await Promise.all([
      productVariantModel.find({ product_id: product._id, status: "active" }),
      productOptionModel.find({ product_id: product._id, status: "active" }),
      productAttributeModel.find({ product_id: product._id, status: "active" }).sort({ sort_order: 1 }),
      productSaleModel.findOne({
        product_id: product._id,
        status: "active",
        start_date: { $lte: now },
        end_date: { $gte: now }
      }),
      shopModel.findOne({ _id: product.shop_id }),
      reviewModel.find({ product_id: product._id, status: "visible" })
        .populate("user_id", "full_name avatar")
        .sort({ createdAt: -1 })
    ]);

    // Trả về ảnh có URL đầy đủ
    const getFullImageUrl = (imagePath) => {
      const fileName = imagePath ? imagePath.split("/").pop() : "prod_special.jpg";
      return `${req.protocol}://${req.get("host")}/images/products/${fileName}`;
    };

    const firstVariantImage = variants.length > 0 ? variants[0].image : null;
    const defaultImage = getFullImageUrl(firstVariantImage);

    const formattedVariants = variants.map(v => ({
      ...v.toObject(),
      image: v.image ? getFullImageUrl(v.image) : defaultImage
    }));

    // Tính toán rating thực tế từ database
    let totalReviews = dbReviews.length;
    let ratingAverage = 5.0;
    if (totalReviews > 0) {
      const sum = dbReviews.reduce((acc, curr) => acc + curr.rating, 0);
      ratingAverage = Math.round((sum / totalReviews) * 10) / 10;
    } else {
      ratingAverage = 0.0;
    }

    // Format list reviews
    const formattedReviews = dbReviews.map(r => {
      const userObj = r.user_id ? r.user_id.toObject() : null;
      let userAvatar = null;
      if (userObj && userObj.avatar) {
        if (userObj.avatar.startsWith("http")) {
          userAvatar = userObj.avatar;
        } else {
          userAvatar = `${req.protocol}://${req.get("host")}/images/users/${userObj.avatar.split("/").pop()}`;
        }
      }

      return {
        _id: r._id,
        rating: r.rating,
        comment: r.comment,
        images: r.images,
        created_at: r.createdAt,
        user: userObj ? {
          full_name: userObj.full_name,
          avatar: userAvatar
        } : { full_name: "Khách TuHu", avatar: null }
      };
    });

    // Tìm các sản phẩm trùng tên ở cửa hàng khác
    const otherProducts = await productModel.find({
      product_name: product.product_name,
      _id: { $ne: product._id },
      status: "active"
    });

    const otherShopsData = await Promise.all(
      otherProducts.map(async (op) => {
        const [opShop, opVariants, opSale] = await Promise.all([
          shopModel.findOne({ _id: op.shop_id }),
          productVariantModel.find({ product_id: op._id, status: "active" }),
          productSaleModel.findOne({
            product_id: op._id,
            status: "active",
            start_date: { $lte: now },
            end_date: { $gte: now }
          })
        ]);

        if (!opShop) return null;

        const basePrice = opVariants.length > 0 ? opVariants[0].price : 0;
        return {
          product_id: op._id,
          shop_id: opShop._id,
          shop_name: opShop.shop_name,
          logo: opShop.logo ? (opShop.logo.startsWith("http") ? opShop.logo : `${req.protocol}://${req.get("host")}/images/shops/${opShop.logo.split("/").pop()}`) : null,
          price: basePrice,
          sale_price: opSale ? opSale.sale_price : (opVariants.length > 0 && opVariants[0].sale_price ? opVariants[0].sale_price : null)
        };
      })
    );

    const otherShops = otherShopsData.filter(item => item !== null);

    dataRes.data = {
      _id: product._id,
      shop_id: product.shop_id,
      global_category_id: product.global_category_id,
      shop_category_id: product.shop_category_id,
      product_name: product.product_name,
      product_slug: product.product_slug,
      description: product.description,
      preparation_time_minutes: product.preparation_time_minutes,
      status: product.status,
      rating: ratingAverage,
      sales_count: product.sales_count || 100,
      price: variants.length > 0 ? variants[0].price : 0,
      image: defaultImage,
      shop: shop ? {
        _id: shop._id,
        shop_name: shop.shop_name,
        address: shop.address,
        phone_number: shop.phone_number,
        logo: shop.logo ? (shop.logo.startsWith("http") ? shop.logo : `${req.protocol}://${req.get("host")}/images/shops/${shop.logo.split("/").pop()}`) : null
      } : null,
      total_reviews: totalReviews,
      reviews: formattedReviews,
      variants: formattedVariants,
      options: options,
      attributes: attributes,
      active_sale: activeSales,
      other_shops: otherShops
    };

  } catch (err) {
    console.error("Get product detail error:", err.message);
    dataRes.msg = "Server error: " + err.message;
    return res.status(500).json(dataRes);
  }

  return res.json(dataRes);
};
