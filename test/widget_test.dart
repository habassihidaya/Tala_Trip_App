import 'package:flutter_test/flutter_test.dart';
import 'package:tala_trip_app/features/rooms/domain/entities/room_entity.dart';
import 'package:tala_trip_app/features/hotels/domain/validation/hotel_validation.dart';

// Replaces the generated counter test: TALA has no counter screen.
void main() {
  test('DZD input converts exactly and rejects invalid money', () {
    expect(RoomEntity.parsePrice('15000'), 1500000);
    expect(RoomEntity.parsePrice(' 1500,50 '), 150050);
    expect(RoomEntity.parsePrice('0.01'), 1);
    expect(RoomEntity.parsePrice('1.1'), 110);
    for (final value in [
      '0',
      '-1',
      'NaN',
      'Infinity',
      '1e4',
      '10.123',
      '1000001',
      '1,000.00',
    ]) {
      expect(RoomEntity.parsePrice(value), isNull, reason: value);
    }
  });
  test('capacity belongs to the selected room type', () {
    RoomEntity room(RoomType type, int capacity) => RoomEntity(
      type: type,
      capacity: capacity,
      priceInCentimes: 200000,
      totalRooms: 3,
    );
    expect(room(RoomType.single, 1).validate(), isNull);
    expect(room(RoomType.single, 2).validate(), isNotNull);
    expect(room(RoomType.double, 2).validate(), isNull);
    expect(room(RoomType.double, 1).validate(), isNotNull);
    expect(room(RoomType.suite, 4).validate(), isNull);
    expect(room(RoomType.suite, 0).validate(), isNotNull);
    expect(room(RoomType.suite, 21).validate(), isNotNull);
    expect(
      const RoomEntity(
        type: RoomType.single,
        capacity: 1,
        priceInCentimes: 0,
        totalRooms: 1,
      ).validate(),
      isNotNull,
    );
    expect(
      const RoomEntity(
        type: RoomType.single,
        capacity: 1,
        priceInCentimes: 100,
        totalRooms: 0,
      ).validate(),
      isNotNull,
    );
  });
  test('map links reject lookalike hosts and executable schemes', () {
    for (final value in [
      'https://maps.app.goo.gl/example',
      'https://www.google.com/maps?q=Alger',
      'https://goo.gl/maps/example',
      'https://maps.google.com/?q=Alger',
    ]) {
      expect(HotelValidation.validMap(value), isTrue);
    }
    for (final value in [
      'javascript:alert(1)',
      'https://maps.app.goo.gl.evil.com/test',
      'https://google.com@evil.com/maps',
      'file:///tmp/image',
      'http://google.com/maps',
    ]) {
      expect(HotelValidation.validMap(value), isFalse);
    }
  });
  test('phone normalization preserves leading zero and country prefix', () {
    expect(HotelValidation.normalizePhone('0550 12 34 56'), '0550123456');
    expect(HotelValidation.validPhone('+213 550 12 34 56'), isTrue);
    expect(HotelValidation.validPhone('021123456'), isTrue);
    expect(HotelValidation.validPhone('123'), isFalse);
  });
}
