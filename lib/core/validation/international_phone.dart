/// Storage uses E.164-shaped numbers, matching Firestore profile rules.
/// Country-specific mobile validation still happens during registration.
class InternationalPhone {
  InternationalPhone._();

  static bool isValid(String value) =>
      RegExp(r'^\+[1-9][0-9]{1,14}$').hasMatch(value);

  /// Also supports older Algerian booking snapshots stored with a leading 0.
  static String? normalizeContact(String value) {
    final input = value.trim();
    if (!RegExp(r'^\+?[0-9\s().-]+$').hasMatch(input)) return null;
    var number = input.replaceAll(RegExp(r'[\s().-]'), '');
    if (number.startsWith('00')) {
      number = '+${number.substring(2)}';
    } else if (RegExp(r'^0[1-9][0-9]{7,8}$').hasMatch(number)) {
      number = '+213${number.substring(1)}';
    }
    return isValid(number) ? number : null;
  }
}
