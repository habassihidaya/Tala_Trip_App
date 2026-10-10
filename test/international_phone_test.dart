import 'package:flutter_test/flutter_test.dart';
import 'package:tala_trip_app/core/validation/international_phone.dart';

void main() {
  test('booking storage accepts international dialing codes', () {
    for (final number in [
      '+213550123456',
      '+33612345678',
      '+447911123456',
      '+14155552671',
    ]) {
      expect(InternationalPhone.isValid(number), isTrue, reason: number);
    }
    for (final number in [
      '0550123456',
      '33612345678',
      '+0123456',
      '+1234567890123456',
      '+33abc',
    ]) {
      expect(InternationalPhone.isValid(number), isFalse, reason: number);
    }
  });

  test(
    'contact links preserve international prefixes and legacy snapshots',
    () {
      expect(
        InternationalPhone.normalizeContact('+33 6 12 34 56 78'),
        '+33612345678',
      );
      expect(
        InternationalPhone.normalizeContact('0044 7911 123456'),
        '+447911123456',
      );
      expect(
        InternationalPhone.normalizeContact('+1 (415) 555-2671'),
        '+14155552671',
      );
      expect(
        InternationalPhone.normalizeContact('0550 12 34 56'),
        '+213550123456',
      );
      expect(
        InternationalPhone.normalizeContact('00213 550123456'),
        '+213550123456',
      );
      for (final value in [
        'call +33612345678',
        '++33612345678',
        '+33?text=hello',
        '123',
        '',
      ]) {
        expect(
          InternationalPhone.normalizeContact(value),
          isNull,
          reason: value,
        );
      }
    },
  );
}
