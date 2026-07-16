const authService = require("../../services/auth.service");
const shopService = require("../../services/shop.service");

class ShopAuthController {
  /**
   * Render Login Page
   */
  async showLogin(req, res) {
    const firebaseConfig = {
      apiKey: process.env.FIREBASE_API_KEY,
      authDomain: process.env.FIREBASE_AUTH_DOMAIN,
      projectId: process.env.FIREBASE_PROJECT_ID,
      storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
      messagingSenderId: process.env.FIREBASE_MESSAGING_SENDER_ID,
      appId: process.env.FIREBASE_APP_ID
    };
    res.render("shop/login", { firebaseConfig, error: req.query.error || null });
  }

  /**
   * Render Register Page
   */
  async showRegister(req, res) {
    const firebaseConfig = {
      apiKey: process.env.FIREBASE_API_KEY,
      authDomain: process.env.FIREBASE_AUTH_DOMAIN,
      projectId: process.env.FIREBASE_PROJECT_ID,
      storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
      messagingSenderId: process.env.FIREBASE_MESSAGING_SENDER_ID,
      appId: process.env.FIREBASE_APP_ID
    };
    res.render("shop/register", { firebaseConfig, error: null });
  }

  /**
   * API Post: Login and create session cookie
   */
  async login(req, res) {
    const { idToken } = req.body;

    try {
      // Server-side validation
      if (!idToken) {
        return res.status(400).json({ status: "error", msg: "Firebase ID Token is required" });
      }

      const { account } = await authService.verifyAndGetAccount(idToken);

      // Create session cookie (Valid for 5 days)
      const expiresIn = 1000 * 60 * 60 * 24 * 5;
      const sessionCookie = await authService.createSessionCookie(idToken, expiresIn);

      // Set cookie configuration
      const options = {
        maxAge: expiresIn,
        httpOnly: true,
        secure: process.env.NODE_ENV === "production",
        sameSite: "Lax"
      };

      res.cookie("session", sessionCookie, options);
      return res.json({ status: "success", msg: "Logged in successfully", role: account.role });
    } catch (err) {
      console.error("Login controller error:", err.message);
      return res.status(401).json({ status: "error", msg: err.message });
    }
  }

  /**
   * API Post: Register shop and owner
   */
  async register(req, res) {
    try {
      const { shopName, ownerName, email, password, phone, address, latitude, longitude } = req.body;

      // Business execution
      const result = await authService.registerShop({
        shopName,
        ownerName,
        email,
        password,
        phone,
        address,
        latitude,
        longitude
      });

      return res.json({ status: "success", msg: "Shop registered successfully!", data: result });
    } catch (err) {
      console.error("Register controller error:", err.message);
      return res.status(400).json({ status: "error", msg: err.message });
    }
  }

  /**
   * API Post: Update shop logo
   */
  async updateLogo(req, res) {
    try {
      if (!req.file) {
        return res.status(400).json({ status: "error", msg: "No file uploaded" });
      }
      const relativePath = `/images/shops/${req.file.filename}`;
      await shopService.updateLogo(req.shop._id, relativePath);

      const absoluteUrl = `${req.protocol}://${req.get("host")}${relativePath}`;
      return res.json({ status: "success", logoUrl: absoluteUrl });
    } catch (err) {
      console.error("Update logo controller error:", err.message);
      return res.status(500).json({ status: "error", msg: err.message });
    }
  }

  /**
   * Action: Logout
   */
  async logout(req, res) {
    res.clearCookie("session");
    return res.redirect("/shop/login");
  }
}

module.exports = new ShopAuthController();
