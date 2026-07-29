const voucherRepository = require("../repositories/voucher.repository");

class VoucherService {
  async getVouchersByShop(shopId) {
    return voucherRepository.findByShopId(shopId);
  }

  async getVouchersByShopPaginated(shopId, page = 1) {
    const parsedPage = Math.max(parseInt(page) || 1, 1);
    const limit = 10;
    const [vouchers, total] = await Promise.all([
      voucherRepository.findByShopIdPaginated(shopId, { page: parsedPage, limit }),
      voucherRepository.countByShopId(shopId),
    ]);
    return {
      vouchers,
      total,
      page: parsedPage,
      totalPages: Math.max(Math.ceil(total / limit), 1),
    };
  }

  async addVoucher(shopId, data) {
    const { voucherCode, voucherName, discountType, discountValue, minOrderAmount, maxDiscountAmount, claimLimit, usageLimit, startDate, endDate } = data;

    if (!voucherCode || !voucherName || !discountType || !startDate || !endDate) {
      throw new Error("Mã voucher, tên, loại giảm giá và thời gian là bắt buộc");
    }

    let parsedDiscountValue = parseFloat(discountValue);
    if (discountType === "percent") {
      if (isNaN(parsedDiscountValue) || parsedDiscountValue <= 0 || parsedDiscountValue > 100) {
        throw new Error("Phần trăm giảm giá phải trong khoảng 1-100");
      }
    } else if (discountType === "amount") {
      if (isNaN(parsedDiscountValue) || parsedDiscountValue <= 0) {
        throw new Error("Số tiền giảm giá phải lớn hơn 0");
      }
    } else if (discountType === "free_shipping") {
      parsedDiscountValue = 0;
    } else {
      throw new Error("Loại giảm giá không hợp lệ");
    }

    const startDateObj = new Date(startDate);
    const endDateObj = new Date(endDate);
    if (endDateObj <= startDateObj) {
      throw new Error("Ngày kết thúc phải sau ngày bắt đầu");
    }

    const existingCode = await voucherRepository.findByCode(voucherCode.trim().toUpperCase());
    if (existingCode) {
      throw new Error("Mã voucher đã tồn tại");
    }

    return voucherRepository.create({
      shop_id: shopId,
      voucher_code: voucherCode.trim().toUpperCase(),
      voucher_name: voucherName.trim(),
      voucher_type: "shop",
      discount_type: discountType,
      discount_value: parsedDiscountValue,
      min_order_amount: minOrderAmount ? parseFloat(minOrderAmount) : 0,
      max_discount_amount: maxDiscountAmount ? parseFloat(maxDiscountAmount) : null,
      claim_limit: claimLimit ? parseInt(claimLimit) : null,
      usage_limit: usageLimit ? parseInt(usageLimit) : null,
      start_date: startDateObj,
      end_date: endDateObj,
      status: "active"
    });
  }

  async editVoucher(shopId, id, data) {
    const voucher = await voucherRepository.findById(id);
    if (!voucher || String(voucher.shop_id) !== String(shopId) || voucher.voucher_type !== "shop") {
      throw new Error("Voucher not found");
    }

    const { voucherCode, voucherName, discountType, discountValue, minOrderAmount, maxDiscountAmount, claimLimit, usageLimit, startDate, endDate, status } = data;
    const updateData = {};

    if (voucherCode && voucherCode.trim().toUpperCase() !== voucher.voucher_code) {
      const existingCode = await voucherRepository.findByCode(voucherCode.trim().toUpperCase());
      if (existingCode) {
        throw new Error("Mã voucher đã tồn tại");
      }
      updateData.voucher_code = voucherCode.trim().toUpperCase();
    }
    if (voucherName) updateData.voucher_name = voucherName.trim();

    const finalDiscountType = discountType || voucher.discount_type;
    if (discountType) updateData.discount_type = discountType;

    if (discountValue !== undefined && discountValue !== "") {
      let parsed = parseFloat(discountValue);
      if (finalDiscountType === "percent") {
        if (isNaN(parsed) || parsed <= 0 || parsed > 100) {
          throw new Error("Phần trăm giảm giá phải trong khoảng 1-100");
        }
      } else if (finalDiscountType === "amount") {
        if (isNaN(parsed) || parsed <= 0) {
          throw new Error("Số tiền giảm giá phải lớn hơn 0");
        }
      } else if (finalDiscountType === "free_shipping") {
        parsed = 0;
      }
      updateData.discount_value = parsed;
    }

    if (minOrderAmount !== undefined) updateData.min_order_amount = minOrderAmount ? parseFloat(minOrderAmount) : 0;
    if (maxDiscountAmount !== undefined) updateData.max_discount_amount = maxDiscountAmount ? parseFloat(maxDiscountAmount) : null;
    if (claimLimit !== undefined) updateData.claim_limit = claimLimit ? parseInt(claimLimit) : null;
    if (usageLimit !== undefined) updateData.usage_limit = usageLimit ? parseInt(usageLimit) : null;
    if (startDate) updateData.start_date = new Date(startDate);
    if (endDate) updateData.end_date = new Date(endDate);
    if (status) updateData.status = status;

    if (updateData.start_date && updateData.end_date && updateData.end_date <= updateData.start_date) {
      throw new Error("Ngày kết thúc phải sau ngày bắt đầu");
    }

    return voucherRepository.update(id, updateData);
  }

  async deleteVoucher(shopId, id) {
    const voucher = await voucherRepository.findById(id);
    if (!voucher || String(voucher.shop_id) !== String(shopId) || voucher.voucher_type !== "shop") {
      throw new Error("Voucher not found");
    }
    return voucherRepository.softDelete(id);
  }

  // --- Platform-wide vouchers (Admin) ---

  async getPlatformVouchers() {
    return voucherRepository.findPlatformVouchers();
  }

  async getPlatformVouchersPaginated(page = 1) {
    const parsedPage = Math.max(parseInt(page) || 1, 1);
    const limit = 10;
    const [vouchers, total] = await Promise.all([
      voucherRepository.findPlatformVouchersPaginated({ page: parsedPage, limit }),
      voucherRepository.countPlatformVouchers(),
    ]);
    return {
      vouchers,
      total,
      page: parsedPage,
      totalPages: Math.max(Math.ceil(total / limit), 1),
    };
  }

  async addPlatformVoucher(data) {
    const { voucherCode, voucherName, discountType, discountValue, minOrderAmount, maxDiscountAmount, claimLimit, usageLimit, startDate, endDate } = data;

    if (!voucherCode || !voucherName || !discountType || !startDate || !endDate) {
      throw new Error("Mã voucher, tên, loại giảm giá và thời gian là bắt buộc");
    }

    let parsedDiscountValue = parseFloat(discountValue);
    if (discountType === "percent") {
      if (isNaN(parsedDiscountValue) || parsedDiscountValue <= 0 || parsedDiscountValue > 100) {
        throw new Error("Phần trăm giảm giá phải trong khoảng 1-100");
      }
    } else if (discountType === "amount") {
      if (isNaN(parsedDiscountValue) || parsedDiscountValue <= 0) {
        throw new Error("Số tiền giảm giá phải lớn hơn 0");
      }
    } else if (discountType === "free_shipping") {
      parsedDiscountValue = 0;
    } else {
      throw new Error("Loại giảm giá không hợp lệ");
    }

    const startDateObj = new Date(startDate);
    const endDateObj = new Date(endDate);
    if (endDateObj <= startDateObj) {
      throw new Error("Ngày kết thúc phải sau ngày bắt đầu");
    }

    const existingCode = await voucherRepository.findByCode(voucherCode.trim().toUpperCase());
    if (existingCode) {
      throw new Error("Mã voucher đã tồn tại");
    }

    return voucherRepository.create({
      shop_id: null,
      voucher_code: voucherCode.trim().toUpperCase(),
      voucher_name: voucherName.trim(),
      voucher_type: "platform",
      discount_type: discountType,
      discount_value: parsedDiscountValue,
      min_order_amount: minOrderAmount ? parseFloat(minOrderAmount) : 0,
      max_discount_amount: maxDiscountAmount ? parseFloat(maxDiscountAmount) : null,
      claim_limit: claimLimit ? parseInt(claimLimit) : null,
      usage_limit: usageLimit ? parseInt(usageLimit) : null,
      start_date: startDateObj,
      end_date: endDateObj,
      status: "active"
    });
  }

  async editPlatformVoucher(id, data) {
    const voucher = await voucherRepository.findById(id);
    if (!voucher || voucher.voucher_type !== "platform") {
      throw new Error("Voucher not found");
    }

    const { voucherCode, voucherName, discountType, discountValue, minOrderAmount, maxDiscountAmount, claimLimit, usageLimit, startDate, endDate, status } = data;
    const updateData = {};

    if (voucherCode && voucherCode.trim().toUpperCase() !== voucher.voucher_code) {
      const existingCode = await voucherRepository.findByCode(voucherCode.trim().toUpperCase());
      if (existingCode) {
        throw new Error("Mã voucher đã tồn tại");
      }
      updateData.voucher_code = voucherCode.trim().toUpperCase();
    }
    if (voucherName) updateData.voucher_name = voucherName.trim();

    const finalDiscountType = discountType || voucher.discount_type;
    if (discountType) updateData.discount_type = discountType;

    if (discountValue !== undefined && discountValue !== "") {
      let parsed = parseFloat(discountValue);
      if (finalDiscountType === "percent") {
        if (isNaN(parsed) || parsed <= 0 || parsed > 100) {
          throw new Error("Phần trăm giảm giá phải trong khoảng 1-100");
        }
      } else if (finalDiscountType === "amount") {
        if (isNaN(parsed) || parsed <= 0) {
          throw new Error("Số tiền giảm giá phải lớn hơn 0");
        }
      } else if (finalDiscountType === "free_shipping") {
        parsed = 0;
      }
      updateData.discount_value = parsed;
    }

    if (minOrderAmount !== undefined) updateData.min_order_amount = minOrderAmount ? parseFloat(minOrderAmount) : 0;
    if (maxDiscountAmount !== undefined) updateData.max_discount_amount = maxDiscountAmount ? parseFloat(maxDiscountAmount) : null;
    if (claimLimit !== undefined) updateData.claim_limit = claimLimit ? parseInt(claimLimit) : null;
    if (usageLimit !== undefined) updateData.usage_limit = usageLimit ? parseInt(usageLimit) : null;
    if (startDate) updateData.start_date = new Date(startDate);
    if (endDate) updateData.end_date = new Date(endDate);
    if (status) updateData.status = status;

    if (updateData.start_date && updateData.end_date && updateData.end_date <= updateData.start_date) {
      throw new Error("Ngày kết thúc phải sau ngày bắt đầu");
    }

    return voucherRepository.update(id, updateData);
  }

  async deletePlatformVoucher(id) {
    const voucher = await voucherRepository.findById(id);
    if (!voucher || voucher.voucher_type !== "platform") {
      throw new Error("Voucher not found");
    }
    return voucherRepository.softDelete(id);
  }
}

module.exports = new VoucherService();
