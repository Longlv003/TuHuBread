const { Server } = require("socket.io");
const cookie = require("cookie");
const { auth } = require("../configs/firebase.config");
const { userModel } = require("../models/user.model");
const { shopModel } = require("../models/shop.model");

let ioInstance = null;

/**
 * Xác định tài khoản đứng sau 1 kết nối socket.
 *
 * Hỗ trợ 2 cách, theo đúng cách từng loại client vốn đã đăng nhập:
 *  - Firebase ID token (app mobile / client tự truyền token).
 *  - Session cookie (shop/admin portal trên web).
 *
 * Trước đây chỉ chấp nhận ID token, nên web bắt buộc phải còn phiên Firebase
 * phía trình duyệt (localStorage) mới kết nối được — trong khi bản thân trang
 * web lại được xác thực bằng session cookie sống tới 5 ngày. Hai nguồn này
 * lệch nhau (xoá dữ liệu trình duyệt, đổi profile, refresh token lỗi...) làm
 * socket chết âm thầm còn trang vẫn chạy bình thường, dẫn tới mất realtime mà
 * không có dấu hiệu gì.
 */
async function resolveSocketUser(socket) {
  const rawToken =
    socket.handshake.auth.token || socket.handshake.headers["authorization"];

  if (rawToken) {
    const decoded = await auth.verifyIdToken(rawToken.replace("Bearer ", ""));
    return userModel.findOne({ firebase_uid: decoded.uid });
  }

  const cookieHeader = socket.handshake.headers.cookie;
  if (cookieHeader) {
    const sessionCookie = cookie.parse(cookieHeader).session;
    if (sessionCookie) {
      const decoded = await auth.verifySessionCookie(sessionCookie, true);
      return userModel.findOne({ firebase_uid: decoded.uid });
    }
  }

  return null;
}

/**
 * Initialize Socket.IO Server
 * @param {import("http").Server} server - Node.js HTTP Server
 */
function initSocket(server) {
  ioInstance = new Server(server, {
    cors: {
      origin: "*",
      methods: ["GET", "POST"]
    }
  });

  // Authentication Middleware for Socket.IO
  ioInstance.use(async (socket, next) => {
    try {
      const user = await resolveSocketUser(socket);

      if (!user) {
        return next(new Error("Authentication error: Account not found"));
      }

      // Allow any role to connect
      socket.user = user;

      // Find the corresponding shop for this shop owner
      if (user.role === "shop_owner") {
        const shop = await shopModel.findOne({ owner_user_id: user._id });
        if (shop) {
          socket.shop = shop;
        }
      }

      next();
    } catch (err) {
      console.error("Socket authentication error:", err.message);
      next(new Error("Authentication error: " + err.message));
    }
  });

  // Connections handler
  ioInstance.on("connection", (socket) => {
    console.log(`📡 Socket connected: ID=${socket.id}, User=${socket.user.full_name}, Role=${socket.user.role}`);

    // Join private user room
    const userRoom = `user:${socket.user._id}`;
    socket.join(userRoom);
    console.log(`🚪 Socket ${socket.id} joined private room: ${userRoom}`);

    // Join room corresponding to the shop
    if (socket.shop) {
      const shopRoom = `shop_${socket.shop._id}`;
      socket.join(shopRoom);
      console.log(`🚪 Socket ${socket.id} joined shop room: ${shopRoom}`);
    }

    // Prepare other common rooms
    if (socket.user.role === "admin") {
      socket.join("admin");
      console.log(`🚪 Socket ${socket.id} joined room: admin`);
    }

    socket.join("notification");

    // Listeners
    socket.on("join_shop", (shopId) => {
      const room = `shop_${shopId}`;
      socket.join(room);
      console.log(`🚪 Socket ${socket.id} manually joined room: ${room}`);
    });

    socket.on("leave_shop", (shopId) => {
      const room = `shop_${shopId}`;
      socket.leave(room);
      console.log(`🚪 Socket ${socket.id} left room: ${room}`);
    });

    socket.on("disconnect", (reason) => {
      console.log(`🔌 Socket disconnected: ID=${socket.id}, Reason=${reason}`);
    });
  });

  return ioInstance;
}

/**
 * Get Socket.IO Instance
 * @returns {Server}
 */
function getIo() {
  if (!ioInstance) {
    throw new Error("Socket.IO has not been initialized!");
  }
  return ioInstance;
}

module.exports = {
  initSocket,
  getIo
};
