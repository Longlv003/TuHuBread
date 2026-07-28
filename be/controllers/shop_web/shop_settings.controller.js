const shopService = require("../../services/shop.service");

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

class ShopSettingsController {
  async showSettings(req, res) {
    try {
      res.render("shop/settings", {
        firebaseConfig: buildFirebaseConfig(),
        shop: req.shop,
        user: req.user,
        title: "Cài đặt cửa hàng",
        activeTab: "settings"
      });
    } catch (err) {
      console.error("Show settings controller error:", err.message);
      res.status(500).render("error", {
        message: "Failed to load settings: " + err.message,
        error: err
      });
    }
  }

  async updateProfile(req, res) {
    try {
      const result = await shopService.updateProfile(req.shop._id, req.body);
      return res.json({ status: "success", msg: "Cập nhật thông tin cửa hàng thành công!", data: result });
    } catch (err) {
      console.error("Update shop profile controller error:", err.message);
      return res.status(400).json({ status: "error", msg: err.message });
    }
  }

  async toggleOpen(req, res) {
    try {
      const { isOpen } = req.body;
      const result = await shopService.toggleOpenStatus(req.shop._id, isOpen);
      return res.json({ status: "success", msg: "Cập nhật trạng thái cửa hàng thành công!", data: result });
    } catch (err) {
      console.error("Toggle shop open controller error:", err.message);
      return res.status(400).json({ status: "error", msg: err.message });
    }
  }

  async updateBanner(req, res) {
    try {
      if (!req.file) {
        return res.status(400).json({ status: "error", msg: "No file uploaded" });
      }
      const relativePath = `/images/shops/${req.file.filename}`;
      await shopService.updateBanner(req.shop._id, relativePath);

      const absoluteUrl = `${req.protocol}://${req.get("host")}${relativePath}`;
      return res.json({ status: "success", msg: "Cập nhật banner thành công!", bannerUrl: absoluteUrl });
    } catch (err) {
      console.error("Update banner controller error:", err.message);
      return res.status(500).json({ status: "error", msg: err.message });
    }
  }
}

module.exports = new ShopSettingsController();
