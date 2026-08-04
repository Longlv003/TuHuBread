const authService = require("../services/auth.service");

/**
 * Authentication Middleware for Shop Portal (Web EJS Pages)
 */
async function authMiddleware(req, res, next) {
  const sessionCookie = req.cookies.session || "";

  if (!sessionCookie) {
    return res.redirect("/shop/login");
  }

  try {
    const { account, shop } = await authService.verifySessionCookie(sessionCookie);

    if (account.role !== "shop_owner" && account.role !== "admin") {
      res.clearCookie("session");
      return res.redirect("/shop/login?error=Access denied");
    }

    // Tài khoản admin không sở hữu shop nào -> shop sẽ là null. Các controller
    // của shop portal đều giả định req.shop tồn tại (vd. req.shop._id), nên nếu
    // để lọt qua đây sẽ crash (500) thay vì báo lỗi rõ ràng.
    if (!shop) {
      return res.status(403).render("error", {
        message: "Tài khoản này không quản lý cửa hàng nào.",
      });
    }

    req.user = account;
    req.shop = shop;

    // Make variables available in EJS views
    res.locals.user = account;
    res.locals.shop = shop;

    next();
  } catch (err) {
    console.error("Session verification failed:", err.message);
    res.clearCookie("session");
    return res.redirect("/shop/login");
  }
}

/**
 * Guest Middleware: Redirect to dashboard if session exists
 */
async function guestMiddleware(req, res, next) {
  const sessionCookie = req.cookies.session || "";

  if (!sessionCookie) {
    return next();
  }

  try {
    const { account } = await authService.verifySessionCookie(sessionCookie);
    if (account.role === "shop_owner" || account.role === "admin") {
      return res.redirect("/shop/dashboard");
    }
    next();
  } catch (_) {
    // If cookie is invalid, proceed to login page normally
    res.clearCookie("session");
    next();
  }
}

/**
 * Role Middleware: Check if user has specific roles
 * @param {string[]} roles
 */
function roleMiddleware(roles) {
  return (req, res, next) => {
    if (!req.user || !roles.includes(req.user.role)) {
      return res.status(403).render("error", {
        message: "Forbidden: You do not have permissions to access this page.",
        error: {}
      });
    }
    next();
  };
}

module.exports = {
  authMiddleware,
  guestMiddleware,
  roleMiddleware
};
