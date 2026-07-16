const { auth } = require("../configs/firebase.config");
const accountRepository = require("../repositories/account.repository");
const shopRepository = require("../repositories/shop.repository");
const mongoose = require("mongoose");

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

    if (account.role !== "shop_owner" && account.role !== "admin") {
      throw new Error("Access denied. Only shop owners can access this portal.");
    }

    // Find shop linked with this owner
    const shop = await shopRepository.findByOwnerId(account._id);

    return { account, shop, decodedToken };
  }

  /**
   * Register a new shop and shop owner account
   * @param {object} registerData
   */
  async registerShop(registerData) {
    const { shopName, ownerName, email, password, phone, address, latitude, longitude } = registerData;

    // Server-side validation
    if (!shopName || !ownerName || !email || !password || !phone || !address) {
      throw new Error("All fields are required");
    }

    if (!email.includes("@")) {
      throw new Error("Invalid email format");
    }

    if (password.length < 6) {
      throw new Error("Password must be at least 6 characters");
    }

    // Check if account or shop already exists
    const existingAccount = await accountRepository.findByEmail(email);
    if (existingAccount) {
      throw new Error("An account with this email is already registered");
    }

    // 1. Create User in Firebase Auth
    let firebaseUser;
    try {
      firebaseUser = await auth.createUser({
        email: email,
        password: password,
        displayName: ownerName,
        phoneNumber: phone.startsWith("+") ? phone : undefined // Firebase requires E.164 format
      });
    } catch (err) {
      throw new Error("Firebase user creation failed: " + err.message);
    }

    const session = await mongoose.startSession();
    session.startTransaction();

    try {
      // 2. Create User Account in MongoDB
      const newAccount = await accountRepository.create({
        firebase_uid: firebaseUser.uid,
        full_name: ownerName,
        email: email,
        role: "shop_owner",
        status: "active"
      });

      // 3. Create Shop in MongoDB
      const shopSlug = shopName.toLowerCase()
        .replace(/ /g, "-")
        .replace(/[^\w-]+/g, "");

      const newShop = await shopRepository.create({
        owner_user_id: newAccount._id,
        shop_name: shopName,
        shop_slug: `${shopSlug}-${Date.now().toString().slice(-4)}`,
        phone_number: phone,
        address: address,
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

      await session.commitTransaction();
      session.endSession();

      return { account: newAccount, shop: newShop };
    } catch (err) {
      await session.abortTransaction();
      session.endSession();

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
    const shop = await shopRepository.findByOwnerId(account._id);
    return { account, shop, decodedClaims };
  }
}

module.exports = new AuthService();
