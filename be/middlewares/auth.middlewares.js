const { auth } = require("../configs/firebase.config");

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

    req.user = decoded; // uid, email, name, picture

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
    console.log("[optionalAuth] Header:", authHeader);

    if (authHeader && authHeader.startsWith("Bearer ")) {
      const token = authHeader.split(" ")[1];
      const decoded = await auth.verifyIdToken(token);
      req.user = decoded; // uid, email, name, picture
      console.log("[optionalAuth] Token verified. UID:", decoded.uid);
    } else {
      console.log("[optionalAuth] No Bearer token found.");
    }
  } catch (error) {
    console.warn("[optionalAuth] Verify token failed:", error.message);
  }
  next();
};

module.exports = {
  firebaseAuth,
  optionalAuth,
};
