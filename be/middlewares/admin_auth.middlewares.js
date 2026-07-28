const authService = require("../services/auth.service");

/**
 * Authentication Middleware for Admin Portal (Web EJS Pages)
 * Uses a separate cookie ("admin_session") from the shop portal ("session")
 * so an account can be logged into both portals independently.
 */
async function adminAuthMiddleware(req, res, next) {
  const sessionCookie = req.cookies.admin_session || "";

  if (!sessionCookie) {
    return res.redirect("/admin/login");
  }

  try {
    const { account } = await authService.verifySessionCookie(sessionCookie);

    if (account.role !== "admin") {
      res.clearCookie("admin_session");
      return res.redirect("/admin/login?error=Access denied");
    }

    req.admin = account;
    res.locals.admin = account;

    next();
  } catch (err) {
    console.error("Admin session verification failed:", err.message);
    res.clearCookie("admin_session");
    return res.redirect("/admin/login");
  }
}

/**
 * Guest Middleware: Redirect to admin dashboard if session exists
 */
async function adminGuestMiddleware(req, res, next) {
  const sessionCookie = req.cookies.admin_session || "";

  if (!sessionCookie) {
    return next();
  }

  try {
    const { account } = await authService.verifySessionCookie(sessionCookie);
    if (account.role === "admin") {
      return res.redirect("/admin/dashboard");
    }
    next();
  } catch (_) {
    res.clearCookie("admin_session");
    next();
  }
}

module.exports = {
  adminAuthMiddleware,
  adminGuestMiddleware,
};
