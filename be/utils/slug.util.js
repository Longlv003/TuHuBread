/**
 * Clean and convert a Vietnamese string to a standard slug
 * @param {string} str
 */
function toSlug(str) {
  if (!str) return "";
  return str
    .toLowerCase()
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/[đĐ]/g, 'd')
    .trim()
    .replace(/[^a-z0-9 -]/g, '')
    .replace(/\s+/g, '-')
    .replace(/-+/g, '-');
}

module.exports = { toSlug };
