const cron = require("node-cron");
const { voucherSaveModel } = require("../models/voucherSave.model");
const notificationService = require("../services/notification.service");

const EXPIRY_WINDOW_HOURS = 24;

/**
 * Báo cho khách hàng những voucher họ đã lưu (chưa dùng) mà sắp hết hạn
 * trong vòng 24h tới. Chạy 1 lần/ngày — mỗi voucher_save chỉ báo 1 lần
 * (đánh dấu expiry_notified) để không báo lặp lại nhiều ngày liền.
 */
async function notifyExpiringVouchers() {
  const now = new Date();
  const windowEnd = new Date(now.getTime() + EXPIRY_WINDOW_HOURS * 60 * 60 * 1000);

  const expiringSaves = await voucherSaveModel
    .find({
      status: "saved",
      expiry_notified: { $ne: true },
      expires_at: { $gte: now, $lte: windowEnd },
      deleted_at: null,
    })
    .populate("voucher_id");

  for (const save of expiringSaves) {
    if (!save.voucher_id) continue;

    await notificationService.notifyUser(save.user_id, {
      title: "Voucher sắp hết hạn!",
      body: `Mã "${save.voucher_code}" của bạn sẽ hết hạn trong vòng 24 giờ tới. Dùng ngay kẻo lỡ!`,
      type: "voucher",
      data: { voucher_id: String(save.voucher_id._id) },
    });

    save.expiry_notified = true;
    await save.save();
  }

  if (expiringSaves.length > 0) {
    console.log(`[voucherExpiry] Đã báo ${expiringSaves.length} voucher sắp hết hạn`);
  }
}

/** Đăng ký chạy job này mỗi ngày lúc 9h sáng. */
function scheduleVoucherExpiryJob() {
  cron.schedule("0 9 * * *", () => {
    notifyExpiringVouchers().catch((err) => console.error("[voucherExpiry] Job failed:", err.message));
  });
}

module.exports = { scheduleVoucherExpiryJob, notifyExpiringVouchers };
