final _nepaliMobileRegExp = RegExp(r'^(96|97|98)\d{8}$');

/// Nepali mobile numbers are 10 digits, starting with 96, 97, or 98
/// (the local part of a +977 number — no country code here).
bool isValidNepaliMobileNumber(String digits) {
  return _nepaliMobileRegExp.hasMatch(digits.trim());
}
