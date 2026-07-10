const db = require("../configs/db");
const { voucherModel } = require("../models/voucher.model");

const now = new Date();
const endDate = new Date(now);
endDate.setDate(endDate.getDate() + 60);

// Voucher áp dụng cho toàn bộ user (voucher_type: "platform", shop_id: null)
const platformVouchers = [
  {
    voucher_code: "WELCOME10",
    voucher_name: "Giảm 10% cho khách hàng mới",
    voucher_type: "platform",
    discount_type: "percent",
    discount_value: 10,
    min_order_amount: 0,
    max_discount_amount: 20000,
    claim_limit: null,
    usage_limit: null,
    start_date: now,
    end_date: endDate,
    status: "active",
  },
  {
    voucher_code: "FREESHIP",
    voucher_name: "Miễn phí vận chuyển",
    voucher_type: "platform",
    discount_type: "free_shipping",
    discount_value: 0,
    min_order_amount: 50000,
    max_discount_amount: null,
    claim_limit: null,
    usage_limit: null,
    start_date: now,
    end_date: endDate,
    status: "active",
  },
  {
    voucher_code: "GIAM20K",
    voucher_name: "Giảm trực tiếp 20.000đ",
    voucher_type: "platform",
    discount_type: "amount",
    discount_value: 20000,
    min_order_amount: 100000,
    max_discount_amount: null,
    claim_limit: null,
    usage_limit: null,
    start_date: now,
    end_date: endDate,
    status: "active",
  },
  {
    voucher_code: "SALE50",
    voucher_name: "Giảm 50% tối đa 30.000đ",
    voucher_type: "platform",
    discount_type: "percent",
    discount_value: 50,
    min_order_amount: 150000,
    max_discount_amount: 30000,
    claim_limit: 100,
    usage_limit: null,
    start_date: now,
    end_date: endDate,
    status: "active",
  },
];

async function seed() {
  for (const voucher of platformVouchers) {
    const result = await voucherModel.findOneAndUpdate(
      { voucher_code: voucher.voucher_code },
      { $setOnInsert: voucher },
      { upsert: true, returnDocument: "after" },
    );
    console.log(`✔ ${result.voucher_code} — ${result.voucher_name}`);
  }
}

db.mongoose.connection.once("open", async () => {
  try {
    await seed();
    console.log("Seed voucher platform hoàn tất.");
  } catch (err) {
    console.error("Seed voucher thất bại:", err.message);
  } finally {
    await db.mongoose.disconnect();
    process.exit(0);
  }
});

db.mongoose.connection.once("error", (err) => {
  console.error("Không thể kết nối MongoDB:", err.message);
  process.exit(1);
});
