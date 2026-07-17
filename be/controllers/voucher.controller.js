const { voucherModel } = require("../models/voucher.model");
const { userModel } = require("../models/user.model");
const { voucherSaveModel } = require("../models/voucherSave.model");
const { auth } = require("../configs/firebase.config");

// GET /api/vouchers
exports.getVouchers = async (req, res) => {
  let dataRes = { msg: "OK", data: null };

  try {
    const { shop_id } = req.query;
    const now = new Date();

    // Lọc voucher đang hoạt động và còn thời hạn sử dụng
    const query = {
      status: "active",
      start_date: { $lte: now },
      end_date: { $gte: now }
    };

    // Nếu chọn shop thì lấy voucher của shop đó HOẶC voucher hệ thống (voucher_type = 'platform')
    if (shop_id) {
      query.$or = [
        { voucher_type: "platform" },
        { voucher_type: "shop", shop_id: shop_id }
      ];
    }

    let vouchers = await voucherModel.find(query);

    // Sử dụng thông tin req.user được gán bởi middleware optionalAuth để lọc các voucher đã lưu
    if (req.user) {
      console.log("[getVouchers] req.user exists, UID:", req.user.uid);
      const user = await userModel.findOne({ firebase_uid: req.user.uid });
      if (user) {
        console.log("[getVouchers] User found in DB, ID:", user._id);
        const savedList = await voucherSaveModel.find({
          user_id: user._id,
          status: { $in: ["saved", "used"] }
        });
        console.log("[getVouchers] Found saved vouchers count:", savedList.length);
        const savedIds = savedList.map(item => item.voucher_id.toString());
        console.log("[getVouchers] Saved voucher IDs:", savedIds);
        vouchers = vouchers.filter(v => !savedIds.includes(v._id.toString()));
      } else {
        console.log("[getVouchers] User not found in DB for UID:", req.user.uid);
      }
    } else {
      console.log("[getVouchers] req.user is null/undefined");
    }

    dataRes.data = vouchers;

  } catch (err) {
    console.error("Get vouchers error:", err.message);
    dataRes.msg = "Server error: " + err.message;
    return res.status(500).json(dataRes);
  }

  return res.json(dataRes);
};

// GET /api/vouchers/saved
exports.getSavedVouchers = async (req, res) => {
  let dataRes = { msg: "OK", data: null };

  try {
    const user = await userModel.findOne({ firebase_uid: req.user.uid });
    if (!user) {
      dataRes.msg = "Không tìm thấy user";
      return res.status(404).json(dataRes);
    }

    const savedVouchers = await voucherSaveModel
      .find({ user_id: user._id, deleted_at: null })
      .populate("voucher_id")
      .sort({ saved_at: -1 });

    dataRes.data = savedVouchers;
    return res.json(dataRes);
  } catch (err) {
    console.error("Get saved vouchers error:", err.message);
    dataRes.msg = "Server error: " + err.message;
    return res.status(500).json(dataRes);
  }
};

// Logic dùng chung: lưu (claim) 1 voucher vào ví của user
async function claimVoucherForUser(user, voucher) {
  const now = new Date();
  if (voucher.status !== "active" || voucher.end_date < now) {
    return { error: "Voucher đã hết hạn hoặc không còn hoạt động" };
  }

  if (voucher.claim_limit && voucher.claimed_count >= voucher.claim_limit) {
    return { error: "Voucher đã hết lượt lưu" };
  }

  const existingSave = await voucherSaveModel.findOne({
    voucher_id: voucher._id,
    user_id: user._id,
  });
  if (existingSave) {
    return { error: "Bạn đã lưu voucher này rồi" };
  }

  const newSave = new voucherSaveModel({
    voucher_id: voucher._id,
    user_id: user._id,
    voucher_code: voucher.voucher_code,
    expires_at: voucher.end_date,
    status: "saved",
    saved_at: new Date(),
  });
  await newSave.save();

  voucher.claimed_count += 1;
  await voucher.save();

  // Ghi lại voucher đã lưu trực tiếp trên user để tiện tra cứu nhanh
  await userModel.updateOne(
    { _id: user._id },
    { $addToSet: { voucher: voucher._id } },
  );

  // Populate voucher_id để FE nhận đủ thông tin voucher (tên, mức giảm...)
  await newSave.populate("voucher_id");

  return { data: newSave };
}

// POST /api/vouchers/:id/save
exports.saveVoucher = async (req, res) => {
  let dataRes = { msg: "OK", data: null };

  try {
    const voucherId = req.params.id;
    const firebaseUid = req.user.uid; // lấy từ middleware firebaseAuth

    const user = await userModel.findOne({ firebase_uid: firebaseUid });
    if (!user) {
      dataRes.msg = "User not found in system";
      return res.status(404).json(dataRes);
    }

    const voucher = await voucherModel.findById(voucherId);
    if (!voucher) {
      dataRes.msg = "Voucher not found";
      return res.status(404).json(dataRes);
    }

    const result = await claimVoucherForUser(user, voucher);
    if (result.error) {
      dataRes.msg = result.error;
      return res.status(400).json(dataRes);
    }

    dataRes.msg = "Voucher saved successfully";
    dataRes.data = result.data;

  } catch (err) {
    console.error("Save voucher error:", err.message);
    dataRes.msg = "Server error: " + err.message;
    return res.status(500).json(dataRes);
  }

  return res.json(dataRes);
};

// POST /api/vouchers/redeem — nhập mã voucher để lưu vào ví (giống Shopee)
exports.redeemVoucherByCode = async (req, res) => {
  let dataRes = { msg: "OK", data: null };

  try {
    const { voucher_code } = req.body;
    if (!voucher_code || !voucher_code.trim()) {
      dataRes.msg = "Vui lòng nhập mã voucher";
      return res.status(400).json(dataRes);
    }

    const user = await userModel.findOne({ firebase_uid: req.user.uid });
    if (!user) {
      dataRes.msg = "Không tìm thấy user";
      return res.status(404).json(dataRes);
    }

    const escapedCode = voucher_code.trim().replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const voucher = await voucherModel.findOne({
      voucher_code: { $regex: `^${escapedCode}$`, $options: "i" },
    });
    if (!voucher) {
      dataRes.msg = "Mã voucher không tồn tại";
      return res.status(404).json(dataRes);
    }

    const result = await claimVoucherForUser(user, voucher);
    if (result.error) {
      dataRes.msg = result.error;
      return res.status(400).json(dataRes);
    }

    dataRes.msg = "Áp dụng mã voucher thành công";
    dataRes.data = result.data;

  } catch (err) {
    console.error("Redeem voucher error:", err.message);
    dataRes.msg = "Server error: " + err.message;
    return res.status(500).json(dataRes);
  }

  return res.json(dataRes);
};
