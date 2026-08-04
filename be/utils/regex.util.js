/**
 * Escape các ký tự đặc biệt của regex trong chuỗi do người dùng nhập, để dùng
 * an toàn trong $regex của MongoDB — tránh ReDoS (regex tự nghĩ ra bởi
 * attacker gây catastrophic backtracking) và tránh regex injection.
 */
function escapeRegex(input) {
  return String(input).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

module.exports = { escapeRegex };
