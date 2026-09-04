/**
 * Bơm menu cho 2 shop "TuhuBread - Mĩ Đình" và "Tuhubread Đông Anh" — cả hai
 * đã có sẵn trong DB (status active, có toạ độ) nhưng gần như trống sản phẩm
 * nên không đủ điều kiện hiện trong "cửa hàng gần bạn" (GET /api/shops chỉ
 * trả về shop có ít nhất 1 sản phẩm status=active, deleted_at=null).
 *
 *   node scripts/seed_mydinh_donganh.js            # bơm dữ liệu
 *   node scripts/seed_mydinh_donganh.js --reset    # gỡ sạch dữ liệu do script này tạo
 *
 * Mọi document script tạo ra đều đánh dấu `_seed` để gỡ lại chính xác.
 */
const db = require("../configs/db");
const { toSlug } = require("../utils/slug.util");

const TAG = "seed_mydinh_donganh_20260905";
const ARGS = process.argv.slice(2);
const RESET = ARGS.includes("--reset");

const ObjectId = db.mongoose.Types.ObjectId;
const oid = () => new ObjectId();

const MYDINH_SHOP_SLUG = "tuhubread---m-nh-1478";
const DONGANH_SHOP_SLUG = "tuhubread-ng-anh-1711";

const MYDINH_PRODUCTS = [
  { name: "Bánh mì pate Mĩ Đình", cat: "Bánh Mì Thịt", prep: 8, img: "/images/products/prod_pate_special.jpg",
    desc: "Pate gan nhà làm, thịt nguội, chả lụa, dưa chua và rau thơm.",
    variants: [["Size thường", 22000, null, 40], ["Size lớn", 28000, 25000, 25]],
    options: [["Thêm trứng ốp la", 7000], ["Thêm pate", 5000]] },
  { name: "Bánh mì xíu mại", cat: "Bánh Mì Thịt", prep: 9, img: "/images/products/prod_8_1.jpg",
    desc: "Xíu mại sốt cà chua đậm đà, ăn kèm đồ chua và rau thơm.",
    variants: [["Size thường", 24000, null, 35]],
    options: [["Thêm xíu mại", 8000], ["Thêm ớt", 0]] },
  { name: "Bánh mì chay Mĩ Đình", cat: "Bánh Mì Chay", prep: 7, img: "/images/products/prod_2_1.jpg",
    desc: "Đậu hũ chiên, nấm xào, rau củ muối chua.",
    variants: [["Size thường", 20000, 18000, 30]],
    options: [["Thêm nấm", 6000]] },
  { name: "Cà phê sữa đá", cat: "Cà Phê", prep: 5, img: "/images/products/prod_4_1.jpg",
    desc: "Cà phê phin truyền thống, sữa đặc béo ngậy.",
    variants: [["Ly M", 18000, null, 50], ["Ly L", 22000, null, 35]],
    options: [["Ít đường", 0], ["Nhiều đá", 0]] },
  { name: "Trà sữa trân châu", cat: "Trà Sữa", prep: 5, img: "/images/products/prod_thai_tea.jpg",
    desc: "Trà sữa béo thơm, trân châu đường đen dẻo dai.",
    variants: [["Size M", 22000, null, 45], ["Size L", 27000, 24000, 30]],
    options: [["Thêm trân châu", 5000], ["70% đường", 0]] },
  { name: "Nước cam ép Mĩ Đình", cat: "Nước Ép & Sinh Tố", prep: 4, img: "/images/products/prod_5_1.jpg",
    desc: "Cam sành vắt tại chỗ, không pha thêm đường.",
    variants: [["Chai 350ml", 28000, null, 25]],
    options: [["Thêm đường", 0]] },
];

const DONGANH_PRODUCTS = [
  { name: "Bánh mì thịt nướng Đông Anh", cat: "Bánh Mì Thịt", prep: 9, img: "/images/products/prod_9_1.jpg",
    desc: "Thịt nướng thơm lừng, đồ chua giòn, rau thơm.",
    variants: [["Size thường", 25000, null, 35], ["Size lớn", 30000, 27000, 20]],
    options: [["Thêm thịt nướng", 8000], ["Thêm chả", 6000]] },
  { name: "Bánh mì trứng ốp la", cat: "Bánh Mì Thịt", prep: 7, img: "/images/products/prod_1_2.jpg",
    desc: "Hai trứng ốp la, pate, dưa leo và hành phi.",
    variants: [["Size thường", 20000, null, 40]],
    options: [["Thêm trứng", 6000]] },
  { name: "Cà phê muối Đông Anh", cat: "Cà Phê", prep: 5, img: "/images/products/prod_4_2.jpg",
    desc: "Cà phê phin, lớp kem muối béo mặn.",
    variants: [["Ly M", 24000, null, 40], ["Ly L", 29000, null, 25]],
    options: [["Thêm kem muối", 7000]] },
  { name: "Sữa chua trân châu", cat: "Đồ Ăn Kèm", prep: 4, img: "/images/products/prod_7_2.jpg",
    desc: "Sữa chua nhà làm, trân châu đường đen.",
    variants: [["1 ly", 24000, null, 35]],
    options: [["Thêm trân châu", 5000]] },
];

async function run() {
  await db.mongoose.connection.asPromise();
  const C = (n) => db.mongoose.connection.db.collection(n);
  const now = new Date();

  if (RESET) {
    const productIds = await C("products").distinct("_id", { _seed: TAG });
    const rv = await C("product_variants").deleteMany({ product_id: { $in: productIds } });
    const ro = await C("product_options").deleteMany({ product_id: { $in: productIds } });
    const rp = await C("products").deleteMany({ _seed: TAG });
    console.log(`Đã gỡ ${rp.deletedCount} sản phẩm, ${rv.deletedCount} biến thể, ${ro.deletedCount} option (_seed=${TAG})`);
    process.exit(0);
  }

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
        is_featured: false, is_new: true,
        storage_note: "Dùng ngay trong ngày, bảo quản nơi thoáng mát.",
        deleted_at: null, _seed: TAG,
        createdAt: now, updatedAt: now,
      });
      for (const [vName, price, salePrice, stock] of p.variants) {
        await C("product_variants").insertOne({
          _id: oid(), product_id: productId, variant_name: vName, variant_slug: toSlug(vName),
          image: p.img, price, sale_price: salePrice, stock_quantity: stock, sold_quantity: 0,
          status: "active", deleted_at: null, _seed: TAG,
          createdAt: now, updatedAt: now,
        });
      }
      for (const [oName, extra] of p.options) {
        await C("product_options").insertOne({
          _id: oid(), product_id: productId, option_name: oName, option_slug: toSlug(oName),
          extra_price: extra, status: "active", deleted_at: null, _seed: TAG,
          createdAt: now, updatedAt: now,
        });
      }
      added++;
    }
    return added;
  }

  const mydinhShop = await C("shops").findOne({ shop_slug: MYDINH_SHOP_SLUG });
  const donganhShop = await C("shops").findOne({ shop_slug: DONGANH_SHOP_SLUG });
  if (!mydinhShop) throw new Error(`Không tìm thấy shop slug=${MYDINH_SHOP_SLUG}`);
  if (!donganhShop) throw new Error(`Không tìm thấy shop slug=${DONGANH_SHOP_SLUG}`);

  const addedMyDinh = await addProducts(mydinhShop, MYDINH_PRODUCTS);
  console.log(`✓ ${mydinhShop.shop_name}: thêm ${addedMyDinh} sản phẩm mới`);

  const addedDongAnh = await addProducts(donganhShop, DONGANH_PRODUCTS);
  console.log(`✓ ${donganhShop.shop_name}: thêm ${addedDongAnh} sản phẩm mới`);

  // Đảm bảo cả 2 shop đang mở để hiện với khách
  await C("shops").updateMany(
    { _id: { $in: [mydinhShop._id, donganhShop._id] } },
    { $set: { is_open: true, status: "active" } },
  );

  process.exit(0);
}

run().catch((err) => {
  console.error("Lỗi:", err.message);
  process.exit(1);
});
