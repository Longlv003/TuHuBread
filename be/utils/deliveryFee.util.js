const { calculateDistanceKm } = require("./distance.util");

const BASE_FEE = 10000; // covers the first BASE_DISTANCE_KM
const BASE_DISTANCE_KM = 2;
const PER_KM_RATE = 4000; // charged for each km beyond BASE_DISTANCE_KM
const FALLBACK_DISTANCE_KM = 3; // used when the address has no coordinates yet
const MAX_DELIVERY_DISTANCE_KM = 30; // ngoài bán kính này thì từ chối giao hàng

// Delivery option multiplies the distance-based fee instead of being a flat amount
const DELIVERY_MULTIPLIERS = {
  priority: 1.5,
  standard: 1.0,
  saving: 0.6
};

/**
 * Calculate the delivery fee for a single shop -> address leg based on real distance.
 * @param {[number, number]|undefined} shopCoordinates [lng, lat]
 * @param {[number, number]|undefined} addressCoordinates [lng, lat]
 * @param {string} deliveryOption "priority" | "standard" | "saving"
 */
function calculateDeliveryFee(shopCoordinates, addressCoordinates, deliveryOption) {
  const multiplier = DELIVERY_MULTIPLIERS[deliveryOption] ?? 1;

  const distanceKm = (shopCoordinates && addressCoordinates)
    ? calculateDistanceKm(shopCoordinates, addressCoordinates)
    : FALLBACK_DISTANCE_KM;

  const extraKm = Math.max(distanceKm - BASE_DISTANCE_KM, 0);
  const fee = (BASE_FEE + extraKm * PER_KM_RATE) * multiplier;

  return Math.round(fee / 1000) * 1000;
}

/**
 * Khoảng cách shop -> địa chỉ giao (km, làm tròn 1 chữ số). Trả về null nếu
 * thiếu toạ độ 1 trong 2 phía (không thể kết luận ngoài phạm vi).
 */
function getDeliveryDistanceKm(shopCoordinates, addressCoordinates) {
  if (!shopCoordinates || !addressCoordinates) return null;
  return Math.round(calculateDistanceKm(shopCoordinates, addressCoordinates) * 10) / 10;
}

/**
 * Lý do không thể giao tới địa chỉ này, hoặc null nếu giao được.
 *
 *  - "missing_address_location": địa chỉ chưa có toạ độ (thường là địa chỉ cũ
 *    tạo trước khi có tính năng chọn trên bản đồ). Phải chặn, vì không có toạ
 *    độ thì không thể biết có nằm trong phạm vi giao hay không — và khách tự
 *    sửa được bằng cách ghim lại địa chỉ trên bản đồ.
 *  - "out_of_range": vượt quá bán kính giao hàng tối đa.
 *
 * Riêng trường hợp SHOP chưa ghim toạ độ thì không chặn: lỗi thuộc phía cửa
 * hàng, khách không tự khắc phục được nên không nên cấm khách đặt hàng.
 */
function getDeliveryBlockReason(shopCoordinates, addressCoordinates) {
  if (!addressCoordinates) return "missing_address_location";
  if (!shopCoordinates) return null;

  const distance = getDeliveryDistanceKm(shopCoordinates, addressCoordinates);
  if (distance !== null && distance > MAX_DELIVERY_DISTANCE_KM) return "out_of_range";
  return null;
}

/** Thông báo tiếng Việt tương ứng với lý do từ [getDeliveryBlockReason]. */
function getDeliveryBlockMessage(reason) {
  switch (reason) {
    case "missing_address_location":
      return "Địa chỉ này chưa có vị trí trên bản đồ. Vui lòng sửa địa chỉ và ghim lại vị trí để tính phí giao hàng.";
    case "out_of_range":
      return `Địa chỉ giao hàng nằm ngoài phạm vi giao hàng (${MAX_DELIVERY_DISTANCE_KM}km)`;
    default:
      return null;
  }
}

module.exports = {
  calculateDeliveryFee,
  getDeliveryDistanceKm,
  getDeliveryBlockReason,
  getDeliveryBlockMessage,
  DELIVERY_MULTIPLIERS,
  MAX_DELIVERY_DISTANCE_KM,
};
