var express = require("express");
var router = express.Router();
var accCtrl = require("../controllers/account.controller");

router.post("/auth/firebase", accCtrl.verifyFirebaseUser);

module.exports = router;
