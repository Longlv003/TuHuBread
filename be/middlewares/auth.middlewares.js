const { auth } = require("../configs/firebase.config");
const { userModel } = require("../models/user.model");

/**
 * Kiểm tra tài khoản trong MongoDB có còn được phép dùng hệ thống không.
 *
 * Firebase chỉ trả lời "token này hợp lệ", nó không biết gì về việc admin đã
 * khoá tài khoản trong DB của mình. Trước đây middleware chỉ verify token nên
 * người dùng bị khoá vẫn đặt hàng bình thường — thao tác khoá ở trang admin
 * gần như vô hiệu.
 *
 * Trả về account nếu hợp lệ; trả về null nếu chưa có bản ghi trong DB (tài
 * khoản Firebase mới, chưa gọi /api/auth/firebase để đồng bộ — vẫn cho đi tiếp
 * như trước để không phá luồng đăng ký).
 * @throws {Error} nếu tài khoản đã bị khoá hoặc đã xoá mềm.
 */
async function assertAccountUsable(firebaseUid) {
  const account = await userModel.findOne({ firebase_uid: firebaseUid });
  if (!account) {
    return null;
  }
  if (account.deleted_at) {
    throw new Error("Tài khoản không còn tồn tại");
  }
  if (account.status === "blocked") {
    throw new Error("Tài khoản của bạn đã bị khóa. Vui lòng liên hệ hỗ trợ.");
  }
  return account;
}

const firebaseAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res.status(401).json({
        message: "Unauthorized - Missing token",
      });
    }

    const token = authHeader.split(" ")[1];

    const decoded = await auth.verifyIdToken(token);

    let account;
    try {
      account = await assertAccountUsable(decoded.uid);
    } catch (blockedErr) {
      // 403 chứ không phải 401: token vẫn hợp lệ, vấn đề nằm ở quyền — client
      // không nên thử refresh token rồi gọi lại vô ích.
      return res.status(403).json({ message: blockedErr.message });
    }

    req.user = decoded; // uid, email, name, picture
    req.account = account; // bản ghi userModel tương ứng (null nếu chưa đồng bộ)

    next();
  } catch (error) {
    return res.status(401).json({
      message: "Unauthorized - Invalid token",
    });
  }
};

const optionalAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (authHeader && authHeader.startsWith("Bearer ")) {
      const token = authHeader.split(" ")[1];
      const decoded = await auth.verifyIdToken(token);
      // Tài khoản bị khoá được coi như khách vãng lai ở các route optional —
      // assertAccountUsable ném lỗi, catch bên dưới nuốt và đi tiếp không có req.user.
      const account = await assertAccountUsable(decoded.uid);
      req.user = decoded; // uid, email, name, picture
      req.account = account;
    }
  } catch (error) {
    console.warn("[optionalAuth] Verify token failed:", error.message);
  }
  next();
};

module.exports = {
  firebaseAuth,
  optionalAuth,
  assertAccountUsable,
};
