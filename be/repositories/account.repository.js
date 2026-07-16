const { userModel } = require("../models/user.model");

class AccountRepository {
  async findById(id) {
    return userModel.findById(id);
  }

  async findByFirebaseUid(uid) {
    return userModel.findOne({ firebase_uid: uid });
  }

  async findByEmail(email) {
    return userModel.findOne({ email: email });
  }

  async create(userData) {
    return userModel.create(userData);
  }

  async update(id, updateData) {
    return userModel.findByIdAndUpdate(id, updateData, { new: true });
  }
}

module.exports = new AccountRepository();
