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

module.exports = firebaseAuth;
