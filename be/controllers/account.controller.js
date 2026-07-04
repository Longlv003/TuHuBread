const { auth } = require("../configs/firebase.config");
const { accModel } = require("../models/account.model");

exports.verifyFirebaseUser = async (req, res) => {
  let dataRes = { msg: "OK", data: null };

  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      dataRes.msg = "Unauthorized: No token provided";
      return res.status(401).json(dataRes);
    }

    const token = authHeader.split(" ")[1];
    const decodedToken = await auth.verifyIdToken(token);

    const { uid, email, name, picture } = decodedToken;
    const provider = decodedToken.firebase?.sign_in_provider;

    let user = await accModel.findOne({
      firebase_uid: uid, // nhớ check schema
    });

    if (!user) {
      user = new accModel({
        firebase_uid: uid,
        email,
        full_name: name || null,
        avatar: picture || null,
        // provider,
      });

      await user.save();
    }

    dataRes.msg = "Verify success";
    dataRes.data = user;

    return res.json(dataRes);
  } catch (err) {
    console.error("Login/Register error:", err.message);

    dataRes.msg = "Invalid Firebase token";
    return res.status(401).json(dataRes);
  }
};
