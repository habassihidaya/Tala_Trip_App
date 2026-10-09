import 'package:phone_numbers_parser/phone_numbers_parser.dart';

class PhoneNumberHelper {
  PhoneNumberHelper._();

  static String? normalize(String? value, {required IsoCode country}) {
    final input = value?.trim() ?? '';

    if (input.isEmpty) return null;

    // Allow digits and common phone-number formatting.
    if (!RegExp(r'^\+?[0-9\s().-]+$').hasMatch(input)) {
      return null;
    }

    final compact = input.replaceAll(RegExp(r'[\s().-]'), '');

    try {
      final number = PhoneNumber.parse(compact, destinationCountry: country);

      // A pasted international number must match the selected prefix.
      if (compact.startsWith('+') &&
          !compact.startsWith('+${number.countryCode}')) {
        return null;
      }

      if (!number.isValid(type: PhoneNumberType.mobile)) {
        return null;
      }

      return number.international;
    } on PhoneNumberException {
      return null;
    }
  }

  static String? validate(String? value, {required IsoCode country}) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter your mobile number.';
    }

    if (normalize(value, country: country) == null) {
      return 'Enter a valid mobile number for the selected dialing code.';
    }

    return null;
  }
}
