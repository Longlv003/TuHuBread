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
          quantity_sold: { $sum: "$details.quantity" },
          revenue: { $sum: "$details.subtotal" }
        }
      },
      { $sort: { quantity_sold: -1 } },
      { $limit: limit }
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
