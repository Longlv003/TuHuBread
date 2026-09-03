/**
 * Các hàm kiểm tra dữ liệu đầu vào dùng chung cho tầng service.
 *
 * Lý do phải kiểm ở server dù form đã có `required` / `min`: mọi endpoint của
 * portal đều là `fetch` POST, các ràng buộc trên HTML chỉ chặn được người dùng
 * thao tác bình thường trên trình duyệt — gửi thẳng bằng curl hay sửa trong
 * DevTools là đi vào DB.
 */

/** Số tiền/số lượng: không âm. Để trống được (trả về `fallback`). */
function parseNonNegativeNumber(value, label, { fallback = 0, integer = false } = {}) {
  if (value === undefined || value === null || value === "") {
    return fallback;
  }
  const parsed = integer ? parseInt(value, 10) : parseFloat(value);
  if (isNaN(parsed) || parsed < 0) {
    throw new Error(`${label} phải là số không âm`);
  }
  return parsed;
}

/** Giới hạn số lượt (lưu/dùng voucher): số nguyên >= 1, để trống = không giới hạn. */
function parseOptionalPositiveInt(value, label) {
  if (value === undefined || value === null || value === "") {
    return null;
  }
  const parsed = parseInt(value, 10);
  if (isNaN(parsed) || parsed < 1) {
    throw new Error(`${label} phải là số nguyên lớn hơn 0`);
  }
  return parsed;
}

/**
 * Ngày hợp lệ.
 *
 * `new Date("abc")` trả về Invalid Date chứ không ném lỗi, và mọi phép so sánh
 * với Invalid Date đều cho `false` — nên nếu không kiểm ở đây thì một chuỗi
 * ngày rác sẽ lọt qua cả các check kiểu "ngày kết thúc phải sau ngày bắt đầu"
 * rồi mới vỡ ở tầng Mongoose với thông báo "Cast to date failed".
 */
function parseRequiredDate(value, label) {
  const date = new Date(value);
  if (isNaN(date.getTime())) {
    throw new Error(`${label} không hợp lệ`);
  }
  return date;
}

/** Như [parseRequiredDate] nhưng cho phép bỏ trống. */
function parseOptionalDate(value, label) {
  if (value === undefined || value === null || value === "") {
    return null;
  }
  return parseRequiredDate(value, label);
}

/**
 * Số điện thoại Việt Nam: bỏ qua khoảng trắng/dấu chấm/gạch nối người dùng gõ,
 * chấp nhận cả di động (0xxxxxxxxx) lẫn cố định có mã vùng, và dạng +84.
 */
function normalizePhone(value, label = "Số điện thoại") {
  const cleaned = String(value || "").replace(/[\s.\-()]/g, "");
  if (!/^(\+84|0)\d{8,10}$/.test(cleaned)) {
    throw new Error(`${label} không hợp lệ (ví dụ: 0912345678)`);
  }
  return cleaned;
}

/** Email — đủ chặt để loại "a@" mà không cố bắt hết mọi biến thể RFC. */
function assertValidEmail(value, label = "Email") {
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(String(value || "").trim())) {
    throw new Error(`${label} không hợp lệ`);
  }
  return String(value).trim();
}

/**
 * Đường dẫn ngoài: chỉ chấp nhận http/https.
 * Chặn các scheme thực thi được như `javascript:` khi link được gắn vào banner
 * rồi mở trên app.
 */
function assertHttpUrl(value, label = "Đường dẫn") {
  if (value === undefined || value === null || value === "") {
    return null;
  }
  let url;
  try {
    url = new URL(String(value).trim());
  } catch (_) {
    throw new Error(`${label} không hợp lệ (phải bắt đầu bằng http:// hoặc https://)`);
  }
  if (url.protocol !== "http:" && url.protocol !== "https:") {
    throw new Error(`${label} không hợp lệ (phải bắt đầu bằng http:// hoặc https://)`);
  }
  return url.toString();
}

/** Chuỗi bắt buộc: chặn cả trường hợp chỉ toàn khoảng trắng. */
function requireText(value, label, { maxLength } = {}) {
  const trimmed = String(value ?? "").trim();
  if (!trimmed) {
    throw new Error(`${label} là bắt buộc`);
  }
  if (maxLength && trimmed.length > maxLength) {
    throw new Error(`${label} không được vượt quá ${maxLength} ký tự`);
  }
  return trimmed;
}

/** Chuỗi tuỳ chọn có giới hạn độ dài. */
function optionalText(value, label, maxLength) {
  if (value === undefined || value === null) {
    return null;
  }
  const trimmed = String(value).trim();
  if (!trimmed) {
    return null;
  }
  if (trimmed.length > maxLength) {
    throw new Error(`${label} không được vượt quá ${maxLength} ký tự`);
  }
  return trimmed;
}

/** Toạ độ GPS trong khoảng hợp lệ. */
function parseCoordinates(latitude, longitude) {
  const lat = parseFloat(latitude);
  const lng = parseFloat(longitude);
  if (isNaN(lat) || isNaN(lng) || lat < -90 || lat > 90 || lng < -180 || lng > 180) {
    throw new Error("Toạ độ vị trí không hợp lệ");
  }
  return { latitude: lat, longitude: lng };
}

/**
 * Giá khuyến mãi: không âm và phải thấp hơn giá gốc — giá KM cao hơn giá bán
 * là vô nghĩa với khách và làm sai mọi phép tính giảm giá ở app.
 */
function parseSalePrice(salePrice, price, label = "Giá khuyến mãi") {
  if (salePrice === undefined || salePrice === null || salePrice === "") {
    return null;
  }
  const parsed = parseFloat(salePrice);
  if (isNaN(parsed) || parsed < 0) {
    throw new Error(`${label} phải là số không âm`);
  }
  if (price !== undefined && price !== null && parsed >= price) {
    throw new Error(`${label} phải nhỏ hơn giá bán`);
  }
  return parsed;
}

module.exports = {
  parseNonNegativeNumber,
  parseOptionalPositiveInt,
  parseRequiredDate,
  parseOptionalDate,
  normalizePhone,
  assertValidEmail,
  assertHttpUrl,
  requireText,
  optionalText,
  parseCoordinates,
  parseSalePrice,
};
