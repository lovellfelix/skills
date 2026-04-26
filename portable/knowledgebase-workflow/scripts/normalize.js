// normalization helper for title/alias/tag matching
module.exports = function normalize(s) {
  if (!s) return '';
  return s.toString().trim().toLowerCase().replace(/[^a-z0-9]+/g,' ').trim();
};
