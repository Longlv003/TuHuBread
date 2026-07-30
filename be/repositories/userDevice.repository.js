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

  /**
   * Đăng ký/cập nhật FCM token cho 1 thiết bị — key theo fcm_token (unique).
   * Token có thể đổi chủ (vd. đăng xuất tài khoản A, đăng nhập B trên cùng
   * máy) nên luôn ghi đè user_id/platform mới nhất.
   */
  async upsertToken({ userId, fcmToken, platform, deviceId, deviceName }) {
    return userDeviceModel.findOneAndUpdate(
      { fcm_token: fcmToken },
      {
        user_id: userId,
        platform,
        device_id: deviceId || null,
        device_name: deviceName || null,
        is_active: true,
        deleted_at: null,
        last_active_at: new Date(),
      },
      { upsert: true, new: true, setDefaultsOnInsert: true },
    );
  }

  /** Ngừng gửi push tới 1 token cụ thể (khi đăng xuất khỏi thiết bị đó). */
  async deactivateToken(fcmToken) {
    return userDeviceModel.findOneAndUpdate(
      { fcm_token: fcmToken },
      { is_active: false },
      { new: true },
    );
  }
}

module.exports = new UserDeviceRepository();
