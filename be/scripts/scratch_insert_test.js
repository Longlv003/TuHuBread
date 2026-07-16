const db = require("../configs/db");
const { reviewModel } = require("../models/review.model");
const { userModel } = require("../models/user.model");
const mongoose = require("mongoose");

async function run() {
  try {
    // Tìm 1 user để làm người review
    let user = await userModel.findOne({ role: "customer" });
    if (!user) {
      // Nếu không có customer nào, lấy user bất kỳ
      user = await userModel.findOne();
    }

    if (!user) {
      console.log("Không tìm thấy user nào trong database để làm review!");
      process.exit(1);
    }

    const productId = "6a4bacd44274d2d16cf34765";
    const shopId = "65e1d84f4e7fb21a30a10001";

    // Tạo order_id giả lập (ObjectId ngẫu nhiên)
    const fakeOrderId = new mongoose.Types.ObjectId();

    // Chèn 1 review mới 4 sao
    const newReview = await reviewModel.create({
      user_id: user._id,
      shop_id: shopId,
      product_id: productId,
      order_id: fakeOrderId,
      rating: 4,
      comment: "Bánh ngon, nhưng giao hơi nguội tí. Vẫn đánh giá 4 sao ủng hộ!",
      images: [],
      status: "visible"
    });

    console.log("Đã chèn review test thành công:", newReview);

  } catch (err) {
    console.error("Lỗi khi chèn review:", err.message);
  } finally {
    mongoose.connection.close();
  }
}

// Đợi kết nối DB rồi chạy
setTimeout(run, 2000);
