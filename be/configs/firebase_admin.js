var admin = require("firebase-admin");

var serviceAccount = require("./tuhubread-1e656-firebase-adminsdk-fbsvc-d6f651fcca.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

module.exports = admin;
