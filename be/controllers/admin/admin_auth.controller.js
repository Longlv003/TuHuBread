const authService = require("../../services/auth.service");

function buildFirebaseConfig() {
  return {
    apiKey: process.env.FIREBASE_API_KEY,
    authDomain: process.env.FIREBASE_AUTH_DOMAIN,
    projectId: process.env.FIREBASE_PROJECT_ID,
    storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
    messagingSenderId: process.env.FIREBASE_MESSAGING_SENDER_ID,
    appId: process.env.FIREBASE_APP_ID
  };
}

class AdminAuthController {
  async showLogin(req, res) {
    res.render("admin/login", { firebaseConfig: buildFirebaseConfig(), error: req.query.error || null });
  }

  async login(req, res) {
    const { idToken } = req.body;

    try {
      if (!idToken) {
        return res.status(400).json({ status: "error", msg: "Firebase ID Token is required" });
      }

      const { account } = await authService.verifyAdminAccount(idToken);

      const expiresIn = 1000 * 60 * 60 * 24 * 5;
      const sessionCookie = await authService.createSessionCookie(idToken, expiresIn);

      const options = {
        maxAge: expiresIn,
        httpOnly: true,
        secure: process.env.NODE_ENV === "production",
        sameSite: "Lax"
      };

      res.cookie("admin_session", sessionCookie, options);
      return res.json({ status: "success", msg: "Logged in successfully", role: account.role });
    } catch (err) {
      console.error("Admin login controller error:", err.message);
      return res.status(401).json({ status: "error", msg: err.message });
    }
  }

  async logout(req, res) {
    res.clearCookie("admin_session");
    return res.redirect("/admin/login");
  }
}

module.exports = new AdminAuthController();
