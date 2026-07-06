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

    // Nếu chọn shop thì lấy voucher của shop đó HOẶC voucher hệ thống (voucher_type = 'system')
    if (shop_id) {
      query.$or = [
        { voucher_type: "system" },
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

// POST /api/vouchers/:id/save
exports.saveVoucher = async (req, res) => {
  let dataRes = { msg: "OK", data: null };

  try {
    const voucherId = req.params.id;
    const firebaseUid = req.user.uid; // lấy từ middleware firebaseAuth

    // 1. Tìm user trong DB
    const user = await userModel.findOne({ firebase_uid: firebaseUid });
    if (!user) {
      dataRes.msg = "User not found in system";
      return res.status(404).json(dataRes);
    }

    // 2. Tìm voucher
    const voucher = await voucherModel.findById(voucherId);
    if (!voucher) {
      dataRes.msg = "Voucher not found";
      return res.status(404).json(dataRes);
    }

    // Kiểm tra hết hạn/trạng thái hoạt động
    const now = new Date();
    if (voucher.status !== "active" || voucher.end_date < now) {
      dataRes.msg = "Voucher has expired or is inactive";
      return res.status(400).json(dataRes);
    }

    // Kiểm tra giới hạn số lượng claim
    if (voucher.claim_limit && voucher.claimed_count >= voucher.claim_limit) {
      dataRes.msg = "Voucher has no more claim slots left";
      return res.status(400).json(dataRes);
    }

    // 3. Kiểm tra xem đã lưu trước đó chưa
    const existingSave = await voucherSaveModel.findOne({
      voucher_id: voucher._id,
      user_id: user._id
    });
    if (existingSave) {
      dataRes.msg = "You have already saved this voucher";
      return res.status(400).json(dataRes);
    }

    // 4. Tiến hành lưu voucher
    const newSave = new voucherSaveModel({
      voucher_id: voucher._id,
      user_id: user._id,
      voucher_code: voucher.voucher_code,
      expires_at: voucher.end_date,
      status: "saved",
      saved_at: new Date()
    });
    await newSave.save();

    // 5. Tăng claimed_count của voucher lên 1
    voucher.claimed_count += 1;
    await voucher.save();

    dataRes.msg = "Voucher saved successfully";
    dataRes.data = newSave;

  } catch (err) {
    console.error("Save voucher error:", err.message);
    dataRes.msg = "Server error: " + err.message;
    return res.status(500).json(dataRes);
  }

  return res.json(dataRes);
};
