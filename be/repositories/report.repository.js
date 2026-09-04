const mongoose = require("mongoose");
const { orderModel } = require("../models/order.model");
const { shopModel } = require("../models/shop.model");
const { productModel } = require("../models/product.model");
const { userModel } = require("../models/user.model");

class ReportRepository {
  async getPlatformRevenueByDay(sinceDate, untilDate) {
    return orderModel.aggregate([
      {
        $match: {
          order_status: "completed",
          deleted_at: null,
          createdAt: { $gte: sinceDate, $lte: untilDate }
        }
      },
      {
        $group: {
          _id: { $dateToString: { format: "%Y-%m-%d", date: "$createdAt" } },
          revenue: { $sum: { $subtract: ["$items_total", "$discount_amount"] } },
          orders_count: { $sum: 1 }
        }
      },
      { $sort: { _id: 1 } }
    ]);
  }

  async getPlatformTopProducts(sinceDate, untilDate, limit = 10) {
    return orderModel.aggregate([
      {
        $match: {
          order_status: "completed",
          deleted_at: null,
          createdAt: { $gte: sinceDate, $lte: untilDate }
        }
      },
      {
        $lookup: {
          from: "order_details",
          localField: "_id",
          foreignField: "order_id",
          as: "details"
        }
      },
      { $unwind: "$details" },
      {
        $group: {
          _id: "$details.product_id",
          product_name: { $first: "$details.product_name" },
          // Mỗi sản phẩm chỉ thuộc đúng 1 shop (không dùng chung giữa các
          // shop), nên $first ở đây luôn đúng — không phải gộp nhiều shop.
          shop_id: { $first: "$shop_id" },
          quantity_sold: { $sum: "$details.quantity" },
          revenue: { $sum: "$details.subtotal" }
        }
      },
      { $sort: { quantity_sold: -1 } },
      { $limit: limit },
      {
        $lookup: {
          from: "shops",
          localField: "shop_id",
          foreignField: "_id",
          as: "shop"
        }
      },
      { $unwind: { path: "$shop", preserveNullAndEmptyArrays: true } },
      {
        $project: {
          product_name: 1,
          quantity_sold: 1,
          revenue: 1,
          shop_name: "$shop.shop_name"
        }
      }
    ]);
  }

  /**
   * Top chi nhánh (shop) theo doanh thu toàn sàn — cùng công thức doanh thu
   * ("items_total - discount_amount", chỉ đơn "completed") với các thống kê
   * khác để nhất quán số liệu trên Dashboard.
   */
  async getPlatformTopShops(sinceDate, untilDate, limit = 10) {
    return orderModel.aggregate([
      {
        $match: {
          order_status: "completed",
          deleted_at: null,
          createdAt: { $gte: sinceDate, $lte: untilDate }
        }
      },
      {
        $group: {
          _id: "$shop_id",
          revenue: { $sum: { $subtract: ["$items_total", "$discount_amount"] } },
          orders_count: { $sum: 1 }
        }
      },
      { $sort: { revenue: -1 } },
      { $limit: limit },
      {
        $lookup: {
          from: "shops",
          localField: "_id",
          foreignField: "_id",
          as: "shop"
        }
      },
      { $unwind: { path: "$shop", preserveNullAndEmptyArrays: true } },
      {
        $project: {
          _id: 0,
          shop_id: "$_id",
          shop_name: "$shop.shop_name",
          logo: "$shop.logo",
          revenue: 1,
          orders_count: 1
        }
      }
    ]);
  }

  async countTotalShops() {
    return shopModel.countDocuments({ deleted_at: null });
  }

  async countTotalProducts() {
    return productModel.countDocuments({ deleted_at: null });
  }

  async countTotalCustomers() {
    return userModel.countDocuments({ role: "customer", deleted_at: null });
  }

  async countTotalOrders() {
    return orderModel.countDocuments({ deleted_at: null });
  }

  async getRevenueByDay(shopId, sinceDate, untilDate) {
    return orderModel.aggregate([
      {
        $match: {
          shop_id: new mongoose.Types.ObjectId(shopId),
          order_status: "completed",
          deleted_at: null,
          createdAt: { $gte: sinceDate, $lte: untilDate }
        }
      },
      {
        $group: {
          _id: { $dateToString: { format: "%Y-%m-%d", date: "$createdAt" } },
          revenue: { $sum: { $subtract: ["$items_total", "$discount_amount"] } },
          orders_count: { $sum: 1 }
        }
      },
      { $sort: { _id: 1 } }
    ]);
  }

  /**
   * Đếm đơn theo TỪNG trạng thái (kể cả huỷ) trong khoảng thời gian.
   * Các thống kê khác chỉ tính đơn "completed", nên đây là chỗ duy nhất nhìn
   * được tỷ lệ đơn bị huỷ.
   */
  async getOrderStatusBreakdown(shopId, sinceDate, untilDate) {
    return orderModel.aggregate([
      {
        $match: {
          shop_id: new mongoose.Types.ObjectId(shopId),
          deleted_at: null,
          createdAt: { $gte: sinceDate, $lte: untilDate }
        }
      },
      { $group: { _id: "$order_status", count: { $sum: 1 } } }
    ]);
  }

  async getTopProducts(shopId, sinceDate, untilDate, limit = 10) {
    return orderModel.aggregate([
      {
        $match: {
          shop_id: new mongoose.Types.ObjectId(shopId),
          order_status: "completed",
          deleted_at: null,
          createdAt: { $gte: sinceDate, $lte: untilDate }
        }
      },
      {
        $lookup: {
          from: "order_details",
          localField: "_id",
          foreignField: "order_id",
          as: "details"
        }
      },
      { $unwind: "$details" },
      {
        $group: {
          _id: "$details.product_id",
          product_name: { $first: "$details.product_name" },
          quantity_sold: { $sum: "$details.quantity" },
          revenue: { $sum: "$details.subtotal" }
        }
      },
      { $sort: { quantity_sold: -1 } },
      { $limit: limit }
    ]);
  }
}

module.exports = new ReportRepository();
