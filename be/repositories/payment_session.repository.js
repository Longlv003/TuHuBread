const { paymentSessionModel } = require("../models/payment_session.model");

/**
 * PaymentSessionRepository — Data Access Layer cho payment_sessions.
 * Chỉ chứa các thao tác DB thuần tuý, không có business logic.
 */
class PaymentSessionRepository {
  /**
   * Tạo mới một payment session.
   * @param {Object} sessionData
   * @returns {Promise<Document>}
   */
  async create(sessionData) {
    return await paymentSessionModel.create(sessionData);
  }

  /**
   * Tìm session theo ID (txnRef).
   * @param {string} id
   * @returns {Promise<Document|null>}
   */
  async findById(id) {
    return await paymentSessionModel.findById(id);
  }

  /**
   * Cập nhật session theo ID.
   * @param {string} id
   * @param {Object} updateData
   * @returns {Promise<Document|null>}
   */
  async updateById(id, updateData) {
    return await paymentSessionModel.findByIdAndUpdate(id, updateData, {
      new: true,
    });
  }

  /**
   * Lấy các session đang PENDING của user.
   * @param {string} userId
   * @returns {Promise<Document[]>}
   */
  async findPendingByUser(userId) {
    return await paymentSessionModel.find({
      user_id: userId,
      status: "PENDING",
    });
  }
}

module.exports = new PaymentSessionRepository();
