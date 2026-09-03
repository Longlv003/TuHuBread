const db = require("../configs/db");
const { shopModel } = require("../models/shop.model");
const reviewService = require("../services/review.service");

/**
 * Tính lại rating_average / total_reviews cho toàn bộ cửa hàng.
 *
 * Chạy 1 lần sau khi thêm phần cập nhật rating tự động: những đánh giá đã có
 * trong DB từ trước đó chưa bao giờ được cộng vào điểm của shop, nên nếu không
 * chạy script này thì các shop cũ vẫn hiển thị "Chưa có đánh giá".
 *
 *   npm run recalc:ratings
 */
async function recalcAll() {
  const shops = await shopModel.find({ deleted_at: null }).select("_id shop_name");

  for (const shop of shops) {
    await reviewService.recalculateShopRating(shop._id);
    const updated = await shopModel.findById(shop._id).select("rating_average total_reviews");
    console.log(
      `✔ ${shop.shop_name} — ${updated.rating_average} sao / ${updated.total_reviews} đánh giá`,
    );
  }

  console.log(`\nĐã tính lại rating cho ${shops.length} cửa hàng.`);
}

db.mongoose.connection.once("open", async () => {
  try {
    await recalcAll();
  } catch (err) {
    console.error("Tính lại rating thất bại:", err.message);
  } finally {
    await db.mongoose.disconnect();
    process.exit(0);
  }
});

db.mongoose.connection.once("error", (err) => {
  console.error("Không thể kết nối MongoDB:", err.message);
  process.exit(1);
});
