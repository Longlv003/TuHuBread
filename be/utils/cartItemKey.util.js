/**
 * Khóa cấu hình duy nhất cho 1 dòng giỏ hàng: product + variant + options
 * (đã sắp xếp). Dùng để so khớp cart item với sản phẩm vừa đặt/thanh toán,
 * nhằm chỉ xoá đúng những sản phẩm đó khỏi giỏ hàng thay vì xoá sạch cả giỏ.
 */
function buildCartItemConfigKey(productId, variantId, optionIds) {
  const sortedOptionIds = (optionIds || []).map(String).sort().join(",");
  return `${productId}|${variantId}|${sortedOptionIds}`;
}

module.exports = { buildCartItemConfigKey };
