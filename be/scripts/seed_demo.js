/**
 * Bơm dữ liệu DEMO cho buổi bảo vệ tốt nghiệp — làm giàu dữ liệu trên CHÍNH
 * các cửa hàng và tài khoản đang có, không tạo shop/tài khoản mới.
 *
 *   node scripts/seed_demo.js            # bơm dữ liệu
 *   node scripts/seed_demo.js --reset    # gỡ sạch dữ liệu do script này tạo
 *
 * Mọi document script tạo ra đều được đánh dấu bằng trường `_seed` nên có thể
 * gỡ lại chính xác, không đụng tới dữ liệu bạn đã nhập tay.
 *
 * KHÔNG đụng tới Firebase Auth — mật khẩu các tài khoản giữ nguyên.
 */
const db = require("../configs/db");
const { toSlug } = require("../utils/slug.util");
const { calculateDeliveryFee } = require("../utils/deliveryFee.util");
const { calculateDistanceKm } = require("../utils/distance.util");

const TAG = "demo_seed_20260904";
const ARGS = process.argv.slice(2);
const RESET = ARGS.includes("--reset");

const ObjectId = db.mongoose.Types.ObjectId;
const oid = () => new ObjectId();
const DAY = 86400000;

/** Shop dùng cho phần demo trực tiếp (Shop Portal + đặt hàng trên app). */
const PRIMARY_SHOP_SLUG = "tuhubread---demo-1298";
/**
 * Shop thứ hai ở gần shop chính. Đang trống (0 sản phẩm) nên không hiện với
 * khách; bơm menu vào để trang chủ app có nhiều hơn một cửa hàng và demo được
 * luồng "đổi cửa hàng thì phải xoá giỏ".
 */
const NEIGHBOR_SHOP_SLUG = "banhmi---van-long-2770";
/** Các shop phụ — chỉ bơm lịch sử đơn để Dashboard Admin toàn sàn có số liệu. */
const SECONDARY_SHOP_SLUGS = [
  "banh-mi-tuhu-le-duan",
  "banh-mi-tuhu-nguyen-van-linh",
  "banh-mi-tuhu-dien-bien-phu",
];

const HISTORY_DAYS = 60;
/** Bán kính tối đa coi là "khách này đặt được ở shop này" (giới hạn giao hàng là 30km). */
const MAX_MATCH_KM = 25;

// ------------------------------------------------------------------ RNG có seed
let seedState = 20260904;
function rnd() {
  seedState = (seedState * 1103515245 + 12345) & 0x7fffffff;
  return seedState / 0x7fffffff;
}
const randInt = (min, max) => min + Math.floor(rnd() * (max - min + 1));
const pick = (arr) => arr[Math.floor(rnd() * arr.length)];
const chance = (p) => rnd() < p;

function dayStart(offsetDays = 0) {
  const d = new Date();
  d.setHours(0, 0, 0, 0);
  d.setDate(d.getDate() - offsetDays);
  return d;
}
function atHour(base, hour) {
  const d = new Date(base);
  d.setHours(hour, randInt(0, 59), randInt(0, 59), 0);
  return d;
}
let codeCounter = 0;
function orderCode() {
  codeCounter += 1;
  return `TH${Date.now().toString(36).toUpperCase().slice(-5)}${codeCounter.toString().padStart(4, "0")}`;
}

// ------------------------------------------------------------------ dữ liệu bổ sung
/** Ảnh gán cho các biến thể đang thiếu ảnh (file có sẵn trong public/images/products). */
const FILLER_IMAGES = [
  "/images/products/prod_1_1.jpg", "/images/products/prod_1_2.jpg", "/images/products/prod_1_3.jpg",
  "/images/products/prod_3_1.jpg", "/images/products/prod_4_1.jpg", "/images/products/prod_special.jpg",
  "/images/products/prod_2_1.jpg", "/images/products/prod_7_1.jpg",
];

/** Sản phẩm thêm cho shop chính để menu dày và có ảnh đẹp. */
const NEW_PRODUCTS = [
  { name: "Bánh mì pate đặc biệt", cat: "Bánh Mì Thịt", prep: 8, img: "/images/products/prod_pate_special.jpg",
    desc: "Pate gan nhà làm, thịt nguội, chả lụa, dưa chua và rau thơm.",
    variants: [["Size thường", 25000, null, 45], ["Size lớn", 32000, 29000, 30]],
    options: [["Thêm trứng ốp la", 7000], ["Thêm pate", 5000], ["Không rau", 0]] },
  { name: "Bánh mì xá xíu", cat: "Bánh Mì Thịt", prep: 8, img: "/images/products/prod_char_siu.jpg",
    desc: "Thịt xá xíu ướp mật ong, nướng thơm, sốt đậm đà.",
    variants: [["Size thường", 27000, null, 40], ["Size lớn", 34000, null, 25]],
    options: [["Thêm chả", 8000], ["Thêm ớt", 0]] },
  { name: "Bánh mì gà xé phô mai", cat: "Bánh Mì Thịt", prep: 9, img: "/images/products/prod_chicken_shred.jpg",
    desc: "Gà xé sợi trộn sốt, phô mai tan chảy, rau tươi.",
    variants: [["Size thường", 26000, null, 38]],
    options: [["Thêm phô mai", 7000], ["Sốt cay", 0]] },
  { name: "Trà sữa Thái xanh", cat: "Trà Sữa", prep: 5, img: "/images/products/prod_thai_tea.jpg",
    desc: "Trà Thái xanh ủ lạnh, sữa béo, thạch dừa giòn.",
    variants: [["Size M", 25000, null, 60], ["Size L", 30000, 27000, 45]],
    options: [["Thêm thạch dừa", 6000], ["Thêm trân châu", 5000], ["70% đường", 0], ["Ít đá", 0]] },
  { name: "Combo TuHu tiết kiệm", cat: "Ăn Sáng Nhẹ", prep: 10, img: "/images/products/prod_combo_tuhu.jpg",
    desc: "Bánh mì pate size lớn + cà phê sữa đá size M.",
    variants: [["Combo 1 người", 45000, 39000, 35], ["Combo 2 người", 85000, 75000, 20]],
    options: [["Đổi sang trà sữa", 8000]] },
  { name: "Nước ép cam tươi", cat: "Nước Ép & Sinh Tố", prep: 4, img: "/images/products/prod_5_1.jpg",
    desc: "Cam sành vắt tại chỗ, không pha thêm đường.",
    variants: [["Chai 350ml", 30000, null, 28]],
    options: [["Thêm đường", 0], ["Không đá", 0]] },
];

/** Menu cho shop hàng xóm — đủ để nó hiện ra với khách và đặt được hàng. */
const NEIGHBOR_PRODUCTS = [
  { name: "Bánh mì chảo Van Long", cat: "Bánh Mì Thịt", prep: 12, img: "/images/products/prod_9_1.jpg",
    desc: "Bánh mì ăn kèm chảo pate, trứng, xúc xích và bò băm.",
    variants: [["Phần 1 người", 45000, null, 35], ["Phần 2 người", 80000, 72000, 20]],
    options: [["Thêm trứng", 7000], ["Thêm xúc xích", 10000]] },
  { name: "Bánh mì trứng ốp la", cat: "Bánh Mì Thịt", prep: 7, img: "/images/products/prod_1_2.jpg",
    desc: "Hai trứng ốp la, pate, dưa leo và hành phi.",
    variants: [["Size thường", 22000, null, 45]],
    options: [["Thêm trứng", 7000], ["Không hành", 0]] },
  { name: "Bánh mì chay thập cẩm", cat: "Bánh Mì Chay", prep: 7, img: "/images/products/prod_2_1.jpg",
    desc: "Đậu hũ chiên, nấm xào, rau củ muối chua.",
    variants: [["Size thường", 20000, 18000, 30]],
    options: [["Thêm nấm", 6000]] },
  { name: "Cà phê muối", cat: "Cà Phê", prep: 5, img: "/images/products/prod_4_2.jpg",
    desc: "Cà phê phin, lớp kem muối béo mặn.",
    variants: [["Ly M", 25000, null, 50], ["Ly L", 30000, null, 35]],
    options: [["Thêm kem muối", 8000], ["Ít đường", 0]] },
  { name: "Sữa chua trân châu", cat: "Đồ Ăn Kèm", prep: 4, img: "/images/products/prod_7_2.jpg",
    desc: "Sữa chua nhà làm, trân châu đường đen.",
    variants: [["1 ly", 25000, null, 40]],
    options: [["Thêm trân châu", 5000]] },
];

/** Địa chỉ Đà Nẵng cấp cho các khách chưa có địa chỉ, để 3 "Cơ sở" có người đặt. */
const DANANG_ADDRESSES = [
  { receiver_name: "Trần Minh Khoa", receiver_phone: "0905112233", address_detail: "215 Nguyễn Văn Linh, Hải Châu, Đà Nẵng", coordinates: [108.2118, 16.0602] },
  { receiver_name: "Lê Thu Trang", receiver_phone: "0905223344", address_detail: "62 Lê Duẩn, Thanh Khê, Đà Nẵng", coordinates: [108.2065, 16.0688] },
  { receiver_name: "Phan Quốc Việt", receiver_phone: "0905334455", address_detail: "180 Điện Biên Phủ, Thanh Khê, Đà Nẵng", coordinates: [108.1948, 16.0661] },
  { receiver_name: "Nguyễn Hoài An", receiver_phone: "0905445566", address_detail: "9 Hoàng Diệu, Hải Châu, Đà Nẵng", coordinates: [108.2180, 16.0650] },
];

const REVIEW_COMMENTS = [
  ["Bánh mì nóng giòn, giao nhanh hơn dự kiến. Sẽ ủng hộ tiếp!", 5],
  ["Đồ ăn ngon, đóng gói cẩn thận, shipper thân thiện.", 5],
  ["Nước uống vừa miệng, giá hợp lý. 5 sao nhé shop.", 5],
  ["Ngon nhưng giao hơi lâu so với thời gian dự kiến.", 4],
  ["Chất lượng ổn định, lần thứ ba đặt rồi.", 5],
  ["Bánh ổn, phần rau hơi ít so với ảnh.", 4],
  ["Trà sữa ngọt hơn mong đợi dù đã chọn 70% đường.", 3],
  ["Rất hài lòng, sẽ giới thiệu cho bạn bè.", 5],
  ["Đóng gói chắc chắn, không bị đổ nước.", 5],
  ["Tạm ổn, mong shop cải thiện tốc độ chuẩn bị.", 3],
];

const NOTIFICATIONS = [
  { title: "Ưu đãi chào mừng", body: "Nhập mã WELCOME10 để giảm 10% cho đơn hàng của bạn.", type: "voucher", sender_type: "admin", ago: 5 },
  { title: "Miễn phí vận chuyển", body: "Áp mã FREESHIP cho đơn từ 50.000đ. Lưu ngay!", type: "voucher", sender_type: "admin", ago: 3 },
  { title: "Đơn hàng đã giao thành công", body: "Đơn hàng của bạn đã hoàn thành. Đánh giá để nhận ưu đãi nhé!", type: "ORDER_COMPLETED", sender_type: "system", ago: 2 },
  { title: "Thanh toán thành công", body: "Thanh toán VNPay cho đơn hàng của bạn đã hoàn tất.", type: "PAYMENT_SUCCESS", sender_type: "system", ago: 2 },
];

// ------------------------------------------------------------------ main
(async () => {
  await db.mongoose.connection.asPromise();
  const C = (n) => db.mongoose.connection.db.collection(n);
  const now = new Date();

  console.log("\n=== DỮ LIỆU DEMO TUHUBREAD ===\n");

  // ================================================================ RESET
  if (RESET) {
    console.log("[reset] Gỡ dữ liệu do script tạo");

    const seededOrderIds = await C("orders").distinct("_id", { _seed: TAG });
    await C("order_details").deleteMany({ order_id: { $in: seededOrderIds } });
    await C("order_status_histories").deleteMany({ order_id: { $in: seededOrderIds } });
    const d1 = await C("orders").deleteMany({ _seed: TAG });
    const d2 = await C("reviews").deleteMany({ _seed: TAG });

    const seededProductIds = await C("products").distinct("_id", { _seed: TAG });
    await C("product_variants").deleteMany({ product_id: { $in: seededProductIds } });
    await C("product_options").deleteMany({ product_id: { $in: seededProductIds } });
    const d3 = await C("products").deleteMany({ _seed: TAG });
    const d4 = await C("addresses").deleteMany({ _seed: TAG });
    const d5 = await C("notifications").deleteMany({ _seed: TAG });

    // trả lại hạn voucher đã gia hạn
    let restored = 0;
    for (const b of await C("_seed_backup").find({ kind: "voucher_end_date" }).toArray()) {
      await C("vouchers").updateOne(
        { _id: b.ref_id },
        { $set: { end_date: b.data.end_date }, $unset: { _seed_prev_end_date: "" } },
      );
      restored++;
    }

    console.log(`  đã gỡ: ${d1.deletedCount} đơn, ${d2.deletedCount} đánh giá, ${d3.deletedCount} sản phẩm, ${d4.deletedCount} địa chỉ, ${d5.deletedCount} thông báo, khôi phục hạn ${restored} voucher`);
    console.log("  (tồn kho đã chỉnh không khôi phục — không ảnh hưởng gì)\n");
    await recalcRatingsAndSold(C);

    // trả lại điểm đánh giá gốc của các shop bị ghi đè
    let ratingRestored = 0;
    for (const b of await C("_seed_backup").find({ kind: "shop_rating" }).toArray()) {
      await C("shops").updateOne(
        { _id: b.ref_id },
        {
          $set: { rating_average: b.data.rating_average, total_reviews: b.data.total_reviews },
          $unset: { _seed_prev_rating: "" },
        },
      );
      ratingRestored++;
    }
    await C("_seed_backup").deleteMany({});
    console.log(`  ✓ khôi phục điểm đánh giá gốc cho ${ratingRestored} cửa hàng`);
    await db.mongoose.connection.close();
    process.exit(0);
  }

  // ================================================================ 1. SHOP
  console.log("[1/7] Xác định cửa hàng");
  const primaryShop = await C("shops").findOne({ shop_slug: PRIMARY_SHOP_SLUG });
  if (!primaryShop) throw new Error(`Không tìm thấy shop chính (slug=${PRIMARY_SHOP_SLUG})`);
  const neighborShop = await C("shops").findOne({ shop_slug: NEIGHBOR_SHOP_SLUG });
  const secondaryShops = await C("shops").find({ shop_slug: { $in: SECONDARY_SHOP_SLUGS } }).toArray();
  const targetShops = [primaryShop, ...(neighborShop ? [neighborShop] : []), ...secondaryShops];

  const primaryOwner = await C("users").findOne({ _id: primaryShop.owner_user_id });
  console.log(`  ★ Shop demo chính : ${primaryShop.shop_name}  (chủ: ${primaryOwner ? primaryOwner.email : "?"})`);
  if (neighborShop) console.log(`    shop hàng xóm    : ${neighborShop.shop_name}`);
  for (const s of secondaryShops) console.log(`    shop phụ         : ${s.shop_name}`);

  // shop chính phải đang mở và có giờ hoạt động
  await C("shops").updateOne(
    { _id: primaryShop._id },
    { $set: { is_open: true, status: "active", open_time: primaryShop.open_time || "06:00", close_time: primaryShop.close_time || "22:00" } },
  );

  // ================================================================ 2. LÀM GIÀU MENU SHOP CHÍNH
  console.log("\n[2/7] Bổ sung menu cho shop demo chính");
  const categories = await C("global_categories").find({ deleted_at: null }).toArray();
  const findCategory = (name) => {
    const slug = toSlug(name);
    return categories.find((c) => c.category_slug === slug)
      || categories.find((c) => toSlug(c.category_name) === slug)
      || categories[0];
  };

  async function addProducts(shop, list) {
    let added = 0;
    for (const p of list) {
      const slug = toSlug(p.name);
      const existing = await C("products").findOne({ shop_id: shop._id, product_slug: slug, deleted_at: null });
      if (existing) continue;

      const productId = oid();
      await C("products").insertOne({
        _id: productId, shop_id: shop._id, global_category_id: findCategory(p.cat)._id,
        product_name: p.name, product_slug: slug, description: p.desc,
        preparation_time_minutes: p.prep, status: "active",
        is_featured: chance(0.5), is_new: true,
        storage_note: "Dùng ngay trong ngày, bảo quản nơi thoáng mát.",
        deleted_at: null, _seed: TAG,
        createdAt: new Date(now.getTime() - randInt(40, 90) * DAY), updatedAt: now,
      });
      for (const [vName, price, salePrice, stock] of p.variants) {
        await C("product_variants").insertOne({
          _id: oid(), product_id: productId, variant_name: vName, variant_slug: toSlug(vName),
          image: p.img, price, sale_price: salePrice, stock_quantity: stock, sold_quantity: 0,
          status: "active", deleted_at: null, _seed: TAG,
          createdAt: new Date(now.getTime() - 60 * DAY), updatedAt: now,
        });
      }
      for (const [oName, extra] of p.options) {
        await C("product_options").insertOne({
          _id: oid(), product_id: productId, option_name: oName, option_slug: toSlug(oName),
          extra_price: extra, status: "active", deleted_at: null, _seed: TAG,
          createdAt: new Date(now.getTime() - 60 * DAY), updatedAt: now,
        });
      }
      added++;
    }
    return added;
  }

  const addedProducts = await addProducts(primaryShop, NEW_PRODUCTS);
  console.log(`  ✓ shop chính: thêm ${addedProducts} sản phẩm mới (có ảnh, biến thể, topping)`);
  if (neighborShop) {
    const n = await addProducts(neighborShop, NEIGHBOR_PRODUCTS);
    await C("shops").updateOne(
      { _id: neighborShop._id },
      { $set: { is_open: true, status: "active", open_time: neighborShop.open_time || "06:30", close_time: neighborShop.close_time || "21:30" } },
    );
    console.log(`  ✓ ${neighborShop.shop_name}: thêm ${n} sản phẩm (để shop này hiện ra với khách)`);
  }

  // nạp lại kho + gán ảnh cho biến thể còn thiếu, trên toàn bộ shop chính
  const primaryProductIds = await C("products").distinct("_id", { shop_id: primaryShop._id, deleted_at: null, status: "active" });
  const primaryVariants = await C("product_variants").find({ product_id: { $in: primaryProductIds }, deleted_at: null }).toArray();

  let restocked = 0, imaged = 0, imgIdx = 0;
  for (const v of primaryVariants) {
    const set = {};
    if (v.stock_quantity <= 0) { set.stock_quantity = randInt(25, 60); set.status = "active"; restocked++; }
    if (!v.image) { set.image = FILLER_IMAGES[imgIdx++ % FILLER_IMAGES.length]; imaged++; }
    if (Object.keys(set).length) await C("product_variants").updateOne({ _id: v._id }, { $set: set });
  }
  console.log(`  ✓ nạp lại kho cho ${restocked} biến thể, gán ảnh cho ${imaged} biến thể`);

  // ================================================================ 3. ĐỊA CHỈ KHÁCH
  console.log("\n[3/7] Khách hàng & địa chỉ giao hàng");
  const customers = await C("users").find({ role: "customer", deleted_at: null, status: "active" }).toArray();

  // cấp địa chỉ Đà Nẵng cho các khách chưa có địa chỉ nào, để 3 "Cơ sở" có người đặt
  const withoutAddress = [];
  for (const u of customers) {
    const n = await C("addresses").countDocuments({ user_id: u._id, deleted_at: null });
    if (n === 0) withoutAddress.push(u);
  }
  let addedAddresses = 0;
  for (let i = 0; i < Math.min(withoutAddress.length, DANANG_ADDRESSES.length); i++) {
    const u = withoutAddress[i];
    const a = DANANG_ADDRESSES[i];
    const dup = await C("addresses").findOne({ user_id: u._id, address_detail: a.address_detail });
    if (dup) continue;
    await C("addresses").insertOne({
      _id: oid(), user_id: u._id, receiver_name: a.receiver_name, receiver_phone: a.receiver_phone,
      address_detail: a.address_detail, label: "home",
      location: { type: "Point", coordinates: a.coordinates },
      is_default: true, deleted_at: null, _seed: TAG,
      createdAt: new Date(now.getTime() - 80 * DAY), updatedAt: now,
    });
    addedAddresses++;
  }
  console.log(`  ✓ cấp thêm ${addedAddresses} địa chỉ (Đà Nẵng) cho khách chưa có địa chỉ`);

  // ghép khách <-> shop theo khoảng cách thực tế
  const allAddresses = await C("addresses").find({ deleted_at: null, "location.coordinates.0": { $exists: true } }).toArray();
  const buyersByShop = new Map();
  for (const s of targetShops) {
    const coords = s.location && s.location.coordinates;
    const list = [];
    for (const a of allAddresses) {
      if (!coords) continue;
      if (calculateDistanceKm(coords, a.location.coordinates) <= MAX_MATCH_KM) {
        list.push({ user_id: a.user_id, address_id: a._id, coordinates: a.location.coordinates });
      }
    }
    buyersByShop.set(String(s._id), list);
    console.log(`  ${list.length ? "✓" : "✖"} ${s.shop_name}: ${list.length} địa chỉ trong bán kính ${MAX_MATCH_KM}km`);
  }

  // ================================================================ 4. VOUCHER
  console.log("\n[4/7] Gia hạn voucher hết hạn");
  const soonThreshold = new Date(now.getTime() + 7 * DAY);
  const newEnd = new Date(now.getTime() + 45 * DAY);
  const shopIdSet = targetShops.map((s) => s._id);
  const expiring = await C("vouchers").find({
    deleted_at: null,
    end_date: { $lt: soonThreshold },
    $or: [{ voucher_type: "platform" }, { shop_id: { $in: shopIdSet } }],
  }).toArray();
  for (const v of expiring) {
    await C("_seed_backup").updateOne(
      { kind: "voucher_end_date", ref_id: v._id },
      { $setOnInsert: { kind: "voucher_end_date", ref_id: v._id, data: { end_date: v.end_date } } },
      { upsert: true },
    );
    await C("vouchers").updateOne({ _id: v._id }, { $set: { end_date: newEnd, status: "active" } });
  }
  console.log(`  ✓ gia hạn ${expiring.length} voucher tới ${newEnd.toISOString().slice(0, 10)} (hạn cũ được lưu lại để --reset khôi phục)`);

  const usableVouchers = await C("vouchers").find({
    deleted_at: null, status: "active",
    start_date: { $lte: now }, end_date: { $gte: now },
    $or: [{ voucher_type: "platform" }, { shop_id: { $in: shopIdSet } }],
  }).toArray();

  // ================================================================ 5. ĐƠN HÀNG
  console.log("\n[5/7] Sinh đơn hàng 60 ngày gần nhất");

  // gom biến thể + topping theo shop
  const poolByShop = new Map();
  for (const s of targetShops) {
    const prodIds = await C("products").distinct("_id", { shop_id: s._id, deleted_at: null, status: "active" });
    const prods = await C("products").find({ _id: { $in: prodIds } }).toArray();
    const prodById = new Map(prods.map((p) => [String(p._id), p]));
    const variants = await C("product_variants").find({
      product_id: { $in: prodIds }, deleted_at: null, status: { $ne: "inactive" },
    }).toArray();
    const options = await C("product_options").find({ product_id: { $in: prodIds }, deleted_at: null, status: "active" }).toArray();
    const optionsByProduct = new Map();
    for (const o of options) {
      const k = String(o.product_id);
      if (!optionsByProduct.has(k)) optionsByProduct.set(k, []);
      optionsByProduct.get(k).push(o);
    }
    poolByShop.set(String(s._id), variants.map((v) => {
      const p = prodById.get(String(v.product_id));
      return {
        product_id: v.product_id, variant_id: v._id,
        product_name: p ? p.product_name : "Sản phẩm",
        variant_name: v.variant_name, image: v.image || null,
        price: v.sale_price || v.price,
        options: optionsByProduct.get(String(v.product_id)) || [],
      };
    }));
  }

  const orderDocs = [], detailDocs = [], historyDocs = [];
  const soldDelta = new Map();
  const completed = [];

  function buildOrder(shop, createdAt, status, paymentMethod) {
    const pool = poolByShop.get(String(shop._id));
    const buyers = buyersByShop.get(String(shop._id));
    if (!pool || !pool.length || !buyers || !buyers.length) return false;

    const buyer = pick(buyers);
    const orderId = oid();

    const chosen = [];
    const used = new Set();
    for (let i = 0, n = randInt(1, 3); i < n; i++) {
      let v = pick(pool), guard = 0;
      while (used.has(String(v.variant_id)) && guard++ < 10) v = pick(pool);
      used.add(String(v.variant_id));
      chosen.push(v);
    }

    let itemsTotal = 0;
    const details = [];
    for (const v of chosen) {
      const qty = randInt(1, 3);
      const selected = [];
      let optionTotal = 0;
      for (const o of v.options) {
        if (o.extra_price > 0 && chance(0.3)) {
          selected.push({ option_id: o._id, option_name: o.option_name, extra_price: o.extra_price });
          optionTotal += o.extra_price;
        }
      }
      const unitPrice = v.price + optionTotal;
      const subtotal = unitPrice * qty;
      itemsTotal += subtotal;
      details.push({
        _id: oid(), order_id: orderId, product_id: v.product_id, variant_id: v.variant_id,
        quantity: qty, product_name: v.product_name, variant_name: v.variant_name,
        product_image: v.image, base_price: v.price, selected_options: selected,
        option_total_price: optionTotal, unit_price: unitPrice, subtotal,
        note: chance(0.15) ? "Ít đá, giao giờ hành chính giúp em" : null,
        deleted_at: null, createdAt, updatedAt: createdAt,
      });
      if (status === "completed") {
        soldDelta.set(String(v.variant_id), (soldDelta.get(String(v.variant_id)) || 0) + qty);
      }
    }

    const deliveryOption = pick(["standard", "standard", "standard", "priority", "saving"]);
    const deliveryFee = calculateDeliveryFee(
      shop.location && shop.location.coordinates,
      buyer.coordinates,
      deliveryOption,
    );

    let voucherId = null, discount = 0;
    if (chance(0.3)) {
      const usable = usableVouchers.filter((v) =>
        itemsTotal >= (v.min_order_amount || 0)
        && (!v.shop_id || String(v.shop_id) === String(shop._id)));
      if (usable.length) {
        const v = pick(usable);
        voucherId = v._id;
        if (v.discount_type === "percent") {
          discount = Math.round(itemsTotal * v.discount_value / 100);
          if (v.max_discount_amount) discount = Math.min(discount, v.max_discount_amount);
        } else if (v.discount_type === "amount") {
          discount = v.discount_value;
        } else {
          discount = v.max_discount_amount ? Math.min(deliveryFee, v.max_discount_amount) : deliveryFee;
        }
        discount = Math.min(discount, itemsTotal);
      }
    }

    const paymentStatus = paymentMethod === "vnpay"
      ? (status === "cancelled" ? "refunded" : "paid")
      : (status === "completed" ? "paid" : "unpaid");

    orderDocs.push({
      _id: orderId, order_code: orderCode(), user_id: buyer.user_id, shop_id: shop._id,
      voucher_id: voucherId, address_id: buyer.address_id, payment_method: paymentMethod,
      delivery_option: deliveryOption, payment_status: paymentStatus, order_status: status,
      items_total: itemsTotal, discount_amount: discount, delivery_fee: deliveryFee,
      total_amount: itemsTotal - discount + deliveryFee,
      note: chance(0.2) ? "Gọi trước khi giao giúp mình nhé." : null,
      stock_restored_at: status === "cancelled" ? new Date(createdAt.getTime() + 10 * 60000) : null,
      deleted_at: null, _seed: TAG, createdAt, updatedAt: createdAt,
    });
    detailDocs.push(...details);

    const flow = ["pending", "confirmed", "preparing", "delivering", "completed"];
    const endIdx = status === "cancelled" ? 1 : flow.indexOf(status) + 1;
    let prev = null;
    for (let i = 0; i < endIdx; i++) {
      const at = new Date(createdAt.getTime() + i * 6 * 60000);
      historyDocs.push({
        _id: oid(), order_id: orderId, from_status: prev, to_status: flow[i],
        changed_by: i === 0 ? buyer.user_id : shop.owner_user_id,
        changed_by_name: i === 0 ? "Khách hàng" : (primaryOwner && String(shop._id) === String(primaryShop._id) ? primaryOwner.full_name : "Chủ cửa hàng"),
        note: null, createdAt: at, updatedAt: at,
      });
      prev = flow[i];
    }
    if (status === "cancelled") {
      const at = new Date(createdAt.getTime() + 12 * 60000);
      historyDocs.push({
        _id: oid(), order_id: orderId, from_status: prev, to_status: "cancelled",
        changed_by: buyer.user_id, changed_by_name: "Khách hàng",
        note: pick(["Khách đổi ý", "Đặt nhầm cửa hàng", "Shop hết nguyên liệu"]),
        createdAt: at, updatedAt: at,
      });
    }

    if (status === "completed") {
      completed.push({ orderId, shop, user_id: buyer.user_id, createdAt, product_id: details[0].product_id });
    }
    return true;
  }

  const HOURS = [7, 8, 9, 11, 12, 13, 16, 17, 18, 19];
  for (let d = HISTORY_DAYS; d >= 1; d--) {
    const base = dayStart(d);
    const weekend = [0, 6].includes(base.getDay());
    for (const s of targetShops) {
      const isPrimary = String(s._id) === String(primaryShop._id);
      let count = isPrimary ? randInt(5, 10) : randInt(2, 5);
      if (weekend) count += 2;
      for (let i = 0; i < count; i++) {
        buildOrder(s, atHour(base, pick(HOURS)), chance(0.88) ? "completed" : "cancelled", chance(0.45) ? "vnpay" : "cash");
      }
    }
  }

  // hôm nay: hàng đợi việc cho shop chính
  const today = dayStart(0);
  for (const status of ["pending", "pending", "pending", "confirmed", "confirmed", "preparing", "preparing", "delivering"]) {
    buildOrder(primaryShop, atHour(today, randInt(7, 9)), status, chance(0.5) ? "vnpay" : "cash");
  }
  for (let i = 0; i < 7; i++) {
    buildOrder(primaryShop, atHour(today, randInt(6, 10)), "completed", chance(0.5) ? "vnpay" : "cash");
  }
  buildOrder(primaryShop, atHour(today, 8), "cancelled", "cash");
  for (const s of targetShops) {
    if (String(s._id) === String(primaryShop._id)) continue;
    for (let i = 0; i < 3; i++) {
      buildOrder(s, atHour(today, randInt(6, 10)), i === 0 ? "pending" : "completed", "cash");
    }
  }

  if (orderDocs.length) {
    await C("orders").insertMany(orderDocs, { ordered: false });
    await C("order_details").insertMany(detailDocs, { ordered: false });
    await C("order_status_histories").insertMany(historyDocs, { ordered: false });
  }
  const primaryOrders = orderDocs.filter((o) => String(o.shop_id) === String(primaryShop._id)).length;
  console.log(`  ✓ ${orderDocs.length} đơn (${primaryOrders} của shop demo chính), ${completed.length} hoàn thành, ${detailDocs.length} dòng chi tiết`);

  // ================================================================ 6. ĐÁNH GIÁ + THÔNG BÁO
  console.log("\n[6/7] Đánh giá & thông báo");
  const reviewDocs = [];
  for (const o of completed) {
    if (!chance(0.45)) continue;
    const [comment, rating] = pick(REVIEW_COMMENTS);
    const at = new Date(o.createdAt.getTime() + 3 * 3600000);
    reviewDocs.push({
      _id: oid(), user_id: o.user_id, shop_id: o.shop._id, product_id: o.product_id,
      order_id: o.orderId, rating, comment, images: [], status: "visible",
      deleted_at: null, _seed: TAG, createdAt: at, updatedAt: at,
    });
  }
  if (reviewDocs.length) await C("reviews").insertMany(reviewDocs, { ordered: false });
  console.log(`  ✓ ${reviewDocs.length} đánh giá`);

  // thông báo cho các khách có đặt hàng ở shop chính
  const primaryBuyers = [...new Set(
    orderDocs.filter((o) => String(o.shop_id) === String(primaryShop._id)).map((o) => String(o.user_id)),
  )].slice(0, 3);
  let notiCount = 0;
  for (const uid of primaryBuyers) {
    for (const n of NOTIFICATIONS) {
      const at = new Date(now.getTime() - n.ago * DAY);
      const exists = await C("notifications").findOne({ user_id: new ObjectId(uid), title: n.title, _seed: TAG });
      if (exists) continue;
      await C("notifications").insertOne({
        _id: oid(), user_id: new ObjectId(uid), title: n.title, body: n.body, type: n.type,
        data: null, is_read: n.ago > 3, sent_at: at, sender_type: n.sender_type,
        sender_shop_id: null, deleted_at: null, _seed: TAG, createdAt: at, updatedAt: at,
      });
      notiCount++;
    }
  }
  console.log(`  ✓ ${notiCount} thông báo cho ${primaryBuyers.length} khách hàng`);

  // ================================================================ 7. TÍNH LẠI SỐ LIỆU
  console.log("\n[7/7] Tính lại tồn kho, lượt bán, điểm đánh giá");
  await recalcRatingsAndSold(C);

  // Cảnh báo sắp hết hàng: hạ tồn kho 3 biến thể. Tránh các món dùng trong
  // kịch bản demo đặt hàng — hết hàng giữa lúc trình bày thì hỏng buổi.
  const keepStocked = ["Bánh mì pate đặc biệt", "Trà sữa Thái xanh", "Cà phê sữa đá", "Combo TuHu tiết kiệm"];
  const keepIds = await C("products").distinct("_id", { shop_id: primaryShop._id, product_name: { $in: keepStocked } });
  const lowStockTargets = await C("product_variants")
    .find({
      product_id: { $in: primaryProductIds.filter((id) => !keepIds.some((k) => String(k) === String(id))) },
      deleted_at: null, status: "active",
    })
    .limit(3).toArray();
  const lowStockNames = [];
  for (let i = 0; i < lowStockTargets.length; i++) {
    await C("product_variants").updateOne({ _id: lowStockTargets[i]._id }, { $set: { stock_quantity: [4, 3, 2][i] } });
    const p = await C("products").findOne({ _id: lowStockTargets[i].product_id });
    lowStockNames.push(`${p ? p.product_name : "?"}/${lowStockTargets[i].variant_name}=${[4, 3, 2][i]}`);
  }
  console.log(`  ✓ tồn kho thấp để demo cảnh báo: ${lowStockNames.join(", ")}`);

  // ================================================================ TỔNG KẾT
  const since = dayStart(29);
  const rev = await C("orders").aggregate([
    { $match: { shop_id: primaryShop._id, order_status: "completed", deleted_at: null, createdAt: { $gte: since } } },
    { $group: { _id: null, revenue: { $sum: { $subtract: ["$items_total", "$discount_amount"] } }, n: { $sum: 1 } } },
  ]).toArray();
  const todayCounts = await C("orders").aggregate([
    { $match: { shop_id: primaryShop._id, deleted_at: null, createdAt: { $gte: today } } },
    { $group: { _id: "$order_status", n: { $sum: 1 } } },
  ]).toArray();
  const shopAfter = await C("shops").findOne({ _id: primaryShop._id });

  console.log("\n=== KẾT QUẢ ===");
  console.log(`  Tổng đơn trong DB      : ${await C("orders").countDocuments({})}`);
  console.log(`  Shop demo chính        : ${primaryShop.shop_name}`);
  console.log(`  Đăng nhập Shop Portal  : ${primaryOwner ? primaryOwner.email : "?"} (mật khẩu giữ nguyên)`);
  console.log(`  Doanh thu 30 ngày      : ${rev.length ? rev[0].revenue.toLocaleString("vi-VN") : 0}đ / ${rev.length ? rev[0].n : 0} đơn`);
  console.log(`  Đơn hôm nay            : ${todayCounts.map((r) => `${r._id}=${r.n}`).join("  ")}`);
  console.log(`  Điểm đánh giá shop     : ${shopAfter.rating_average}★ (${shopAfter.total_reviews} đánh giá)`);
  console.log("\n  Admin Portal : http://localhost:3000/admin/login");
  console.log("  Shop  Portal : http://localhost:3000/shop/login");
  console.log("\n  Gỡ lại: node scripts/seed_demo.js --reset\n");

  await db.mongoose.connection.close();
  process.exit(0);
})().catch((err) => {
  console.error("\n✖ THẤT BẠI:", err);
  process.exit(1);
});

/** Tính lại sold_quantity của biến thể và rating của shop từ dữ liệu thật. */
async function recalcRatingsAndSold(C) {
  const soldAgg = await C("orders").aggregate([
    { $match: { order_status: "completed", deleted_at: null } },
    { $lookup: { from: "order_details", localField: "_id", foreignField: "order_id", as: "d" } },
    { $unwind: "$d" },
    { $group: { _id: "$d.variant_id", qty: { $sum: "$d.quantity" } } },
  ]).toArray();
  const soldMap = new Map(soldAgg.map((r) => [String(r._id), r.qty]));

  const allVariantIds = await C("product_variants").distinct("_id", { deleted_at: null });
  const ops = allVariantIds.map((id) => ({
    updateOne: { filter: { _id: id }, update: { $set: { sold_quantity: soldMap.get(String(id)) || 0 } } },
  }));
  for (let i = 0; i < ops.length; i += 500) {
    await C("product_variants").bulkWrite(ops.slice(i, i + 500));
  }

  const ratingAgg = await C("reviews").aggregate([
    { $match: { status: "visible", deleted_at: null } },
    { $group: { _id: "$shop_id", avg: { $avg: "$rating" }, n: { $sum: 1 } } },
  ]).toArray();
  for (const r of ratingAgg) {
    const shop = await C("shops").findOne({ _id: r._id });
    if (!shop) continue;
    // Sao lưu điểm cũ ở collection riêng (không nhét field lạ vào document
    // shop — API /api/shops trả nguyên document về cho app).
    await C("_seed_backup").updateOne(
      { kind: "shop_rating", ref_id: r._id },
      { $setOnInsert: { kind: "shop_rating", ref_id: r._id, data: { rating_average: shop.rating_average, total_reviews: shop.total_reviews } } },
      { upsert: true },
    );
    await C("shops").updateOne(
      { _id: r._id },
      { $set: { rating_average: Math.round(r.avg * 10) / 10, total_reviews: r.n }, $unset: { _seed_prev_rating: "" } },
    );
  }
  console.log(`  ✓ cập nhật lượt bán cho ${ops.length} biến thể, điểm đánh giá cho ${ratingAgg.length} cửa hàng`);
}
