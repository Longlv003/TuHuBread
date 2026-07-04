const mongoose = require("mongoose");
require("dotenv").config();

mongoose
  .connect(process.env.MONGOOSE_URL)
  .then(() => {
    console.log("Database connected successfully");
  })
  .catch((err) => {
    console.log("Error connecting to database");
    console.log(err.message);
  });

module.exports = { mongoose };
