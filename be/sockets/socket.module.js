const { Server } = require("socket.io");
const { auth } = require("../configs/firebase.config");
const { userModel } = require("../models/user.model");
const { shopModel } = require("../models/shop.model");

let ioInstance = null;

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
      const token = socket.handshake.auth.token || socket.handshake.headers["authorization"];
      if (!token) {
        return next(new Error("Authentication error: Token is required"));
      }

      // Verify token via Firebase Admin
      const decodedToken = await auth.verifyIdToken(token.replace("Bearer ", ""));
      const user = await userModel.findOne({ firebase_uid: decodedToken.uid });

      if (!user) {
        return next(new Error("Authentication error: Account not found"));
      }

      // Allow shop_owner and admin (if applicable)
      if (user.role !== "shop_owner" && user.role !== "admin") {
        return next(new Error("Authentication error: Access denied. Only shop owners allowed."));
      }

      socket.user = user;

      // Find the corresponding shop for this shop owner
      if (user.role === "shop_owner") {
        const shop = await shopModel.findOne({ owner_user_id: user._id });
        if (!shop) {
          return next(new Error("Authentication error: No shop associated with this owner"));
        }
        socket.shop = shop;
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

    // Join room corresponding to the shop
    if (socket.shop) {
      const shopRoom = `shop_${socket.shop._id}`;
      socket.join(shopRoom);
      console.log(`🚪 Socket ${socket.id} joined room: ${shopRoom}`);
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
