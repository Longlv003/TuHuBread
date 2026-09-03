const { auth } = require("../configs/firebase.config");
const accountRepository = require("../repositories/account.repository");
const shopRepository = require("../repositories/shop.repository");
const { assertValidEmail, normalizePhone, requireText } = require("../utils/validate.util");

/**
 * Chặn tài khoản đã bị admin khoá / xoá mềm ở mọi cửa vào của portal web.
 * Firebase vẫn coi session cookie là hợp lệ sau khi admin khoá tài khoản trong
 * MongoDB, nên nếu không kiểm tra ở đây thì chủ shop bị khoá vẫn vào được
 * dashboard cho tới khi cookie hết hạn (5 ngày).
 */
function assertAccountUsable(account) {
  if (account.deleted_at) {
    throw new Error("Tài khoản không còn tồn tại");
  }
  if (account.status === "blocked") {
    throw new Error("Tài khoản đã bị khóa. Vui lòng liên hệ quản trị viên.");
  }
}

class AuthService {
  /**
   * Verify Firebase ID Token and get/create local user session
   * @param {string} idToken
   */
  async verifyAndGetAccount(idToken) {
    if (!idToken) {
      throw new Error("ID Token is required");
    }

    // Verify token with Firebase admin sdk
    const decodedToken = await auth.verifyIdToken(idToken);
    const firebaseUid = decodedToken.uid;

    // Find account in MongoDB
    const account = await accountRepository.findByFirebaseUid(firebaseUid);
    if (!account) {
      throw new Error("Account is not registered in our database.");
    }
    assertAccountUsable(account);

    if (account.role !== "shop_owner" && account.role !== "admin") {
      throw new Error("Access denied. Only shop owners can access this portal.");
    }

    // Find shop linked with this owner
    const shop = await shopRepository.findByOwnerId(account._id);

    return { account, shop, decodedToken };
  }

  /**
   * Verify Firebase ID Token and require an "admin" role account (platform admin portal)
   * @param {string} idToken
   */
  async verifyAdminAccount(idToken) {
    if (!idToken) {
      throw new Error("ID Token is required");
    }

    const decodedToken = await auth.verifyIdToken(idToken);
    const firebaseUid = decodedToken.uid;

    const account = await accountRepository.findByFirebaseUid(firebaseUid);
    if (!account) {
      throw new Error("Account is not registered in our database.");
    }
    assertAccountUsable(account);

    if (account.role !== "admin") {
      throw new Error("Access denied. Only system administrators can access this portal.");
    }

    return { account, decodedToken };
  }

  /**
   * Register a new shop and shop owner account
   * @param {object} registerData
   */
  async registerShop(registerData) {
    const { shopName, ownerName, email, password, phone, address, latitude, longitude } = registerData;

    // Server-side validation
    if (!shopName || !ownerName || !email || !password || !phone || !address) {
      throw new Error("Vui lòng điền đầy đủ thông tin");
    }

    const trimmedShopName = requireText(shopName, "Tên cửa hàng", { maxLength: 120 });
    const trimmedOwnerName = requireText(ownerName, "Tên chủ cửa hàng", { maxLength: 120 });
    const trimmedAddress = requireText(address, "Địa chỉ", { maxLength: 255 });
    const validEmail = assertValidEmail(email);
    // Chuẩn hoá luôn để số lưu trong DB thống nhất, không lẫn "0912 345 678"
    // với "0912345678" khiến tra cứu/gọi điện bị lệch.
    const normalizedPhone = normalizePhone(phone);

    if (password.length < 6) {
      throw new Error("Mật khẩu phải có ít nhất 6 ký tự");
    }

    // Check if account or shop already exists
    const existingAccount = await accountRepository.findByEmail(validEmail);
    if (existingAccount) {
      throw new Error("An account with this email is already registered");
    }

    // 1. Create User in Firebase Auth
    let firebaseUser;
    try {
      firebaseUser = await auth.createUser({
        email: validEmail,
        password: password,
        displayName: trimmedOwnerName,
        phoneNumber: normalizedPhone.startsWith("+") ? normalizedPhone : undefined // Firebase requires E.164 format
      });
    } catch (err) {
      throw new Error("Firebase user creation failed: " + err.message);
    }

    // Note: this MongoDB deployment is a standalone instance (no replica set), so
    // multi-document transactions aren't available here. Create sequentially and
    // roll back (delete the account + Firebase user) manually if the shop insert fails.
    let newAccount;
    try {
      // 2. Create User Account in MongoDB
      newAccount = await accountRepository.create({
        firebase_uid: firebaseUser.uid,
        full_name: trimmedOwnerName,
        email: validEmail,
        role: "shop_owner",
        status: "active"
      });

      // 3. Create Shop in MongoDB
      const shopSlug = trimmedShopName.toLowerCase()
        .replace(/ /g, "-")
        .replace(/[^\w-]+/g, "");

      const newShop = await shopRepository.create({
        owner_user_id: newAccount._id,
        shop_name: trimmedShopName,
        shop_slug: `${shopSlug}-${Date.now().toString().slice(-4)}`,
        phone_number: normalizedPhone,
        address: trimmedAddress,
        location: {
          type: "Point",
          coordinates: [
            longitude ? parseFloat(longitude) : 108.2201,
            latitude ? parseFloat(latitude) : 16.0612
          ]
        },
        rating_average: 0.0,
        total_reviews: 0,
        is_open: true,
        status: "active"
      });

      return { account: newAccount, shop: newShop };
    } catch (err) {
      // Clean up MongoDB account if it was created but the shop insert failed
      if (newAccount) {
        try {
          await accountRepository.deleteById(newAccount._id);
        } catch (delErr) {
          console.error("Cleanup MongoDB account failed:", delErr.message);
        }
      }

      // Clean up Firebase User if DB insertion fails
      try {
        await auth.deleteUser(firebaseUser.uid);
      } catch (delErr) {
        console.error("Cleanup Firebase user failed:", delErr.message);
      }

      throw err;
    }
  }

  /**
   * Generate Firebase session cookie
   * @param {string} idToken
   * @param {number} expiresInMs
   */
  async createSessionCookie(idToken, expiresInMs = 1000 * 60 * 60 * 24 * 5) { // 5 Days
    return auth.createSessionCookie(idToken, { expiresIn: expiresInMs });
  }

  /**
   * Verify Session Cookie
   * @param {string} sessionCookie
   */
  async verifySessionCookie(sessionCookie) {
    if (!sessionCookie) {
      throw new Error("No session cookie provided");
    }
    const decodedClaims = await auth.verifySessionCookie(sessionCookie, true);
    const account = await accountRepository.findByFirebaseUid(decodedClaims.uid);
    if (!account) {
      throw new Error("Account not found");
    }
    assertAccountUsable(account);
    const shop = await shopRepository.findByOwnerId(account._id);
    return { account, shop, decodedClaims };
  }
}

module.exports = new AuthService();
