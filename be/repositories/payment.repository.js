const { paymentModel } = require("../models/payment.model");

class PaymentRepository {
  async createPayment(paymentData) {
    return await paymentModel.create(paymentData);
  }

  async findByTxnRef(txnRef) {
    return await paymentModel.findOne({ txn_ref: txnRef });
  }

  async findByOrderId(orderId) {
    return await paymentModel.findOne({ order_id: orderId });
  }

  async updatePaymentStatus(txnRef, status, details = {}) {
    const updateData = { status, ...details };
    return await paymentModel.findOneAndUpdate({ txn_ref: txnRef }, updateData, { new: true });
  }
}

module.exports = new PaymentRepository();
