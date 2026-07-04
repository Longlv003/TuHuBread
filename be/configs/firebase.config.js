const { initializeApp, cert } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");

const serviceAccount = require("./tuhubread-1e656-firebase-adminsdk-fbsvc-d6f651fcca.json");

const app = initializeApp({
  credential: cert(serviceAccount),
});

const auth = getAuth(app);

module.exports = { app, auth };
