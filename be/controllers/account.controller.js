const { auth } = require("../configs/firebase.config");
const { userModel } = require("../models/user.model");

exports.verifyFirebaseUser = async (req, res) => {
  let dataRes = { msg: "OK", data: null };

  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      dataRes.msg = "Unauthorized: No token provided";
      return res.status(401).json(dataRes);
    }

    const token = authHeader.split(" ")[1];
    const decodedToken = await auth.verifyIdToken(token);

    const { uid, email, name, picture } = decodedToken;
    const provider = decodedToken.firebase?.sign_in_provider;

    let user = await userModel.findOne({ firebase_uid: uid });

    if (!user) {
      user = new userModel({
        firebase_uid: uid,
        email,
        full_name: name || (email ? email.split("@")[0] : "Người dùng"),
        avatar: picture || null,
        role: "customer",
      });
      await user.save();
    } else {
      // Cập nhật thông tin avatar và họ tên mới nhất từ Google/Facebook nếu có thay đổi
      let hasChanges = false;
      if (picture && user.avatar !== picture) {
        user.avatar = picture;
        hasChanges = true;
      }
      if (name && user.full_name !== name) {
        user.full_name = name;
        hasChanges = true;
      }
      if (hasChanges) {
        await user.save();
      }
    }

    dataRes.msg = "Verify success";
    dataRes.data = user;

    return res.json(dataRes);
  } catch (err) {
    console.error("Login/Register error:", err.message);

    dataRes.msg = "Invalid Firebase token";
    return res.status(401).json(dataRes);
  }
};

// PUT /api/account/profile
exports.updateProfile = async (req, res) => {
  let dataRes = { msg: "OK", data: null };

  try {
    const user = await userModel.findOne({ firebase_uid: req.user.uid });

    if (!user) {
      dataRes.msg = "Không tìm thấy user";
      return res.status(404).json(dataRes);
    }

    const { full_name, phone } = req.body;

    if (full_name !== undefined) user.full_name = full_name;
    if (phone !== undefined) user.phone = phone;

    await user.save();

    dataRes.data = user;
    return res.json(dataRes);
  } catch (err) {
    console.error("Update profile error:", err.message);
    dataRes.msg = "Server error: " + err.message;
    return res.status(500).json(dataRes);
  }
};

// POST /api/account/avatar
exports.uploadAvatar = async (req, res) => {
  let dataRes = { msg: "OK", data: null };

  try {
    if (!req.file) {
      dataRes.msg = "Không có file ảnh nào được gửi lên";
      return res.status(400).json(dataRes);
    }

    const user = await userModel.findOne({ firebase_uid: req.user.uid });

    if (!user) {
      dataRes.msg = "Không tìm thấy user";
      return res.status(404).json(dataRes);
    }

    user.avatar = `${req.protocol}://${req.get("host")}/images/avatars/${req.file.filename}`;
    await user.save();

    dataRes.data = user;
    return res.json(dataRes);
  } catch (err) {
    console.error("Upload avatar error:", err.message);
    dataRes.msg = "Server error: " + err.message;
    return res.status(500).json(dataRes);
  }
};
