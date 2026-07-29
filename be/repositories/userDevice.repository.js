const { userDeviceModel } = require("../models/userDevice.model");

class UserDeviceRepository {
  async findActiveTokensByUserId(userId) {
    const devices = await userDeviceModel.find({ user_id: userId, is_active: true, deleted_at: null }).select("fcm_token");
    return devices.map(d => d.fcm_token);
  }

  async findAllActiveTokens() {
    const devices = await userDeviceModel.find({ is_active: true, deleted_at: null }).select("fcm_token");
    return devices.map(d => d.fcm_token);
  }
}

module.exports = new UserDeviceRepository();
