import 'package:tala_trip_app/features/rooms/domain/entities/room_entity.dart';

import '../../domain/entities/booking_availability.dart';
import '../../domain/entities/booking_dates.dart';

class BookingAvailabilityModel {
  final BookingAvailability _availability;

  const BookingAvailabilityModel.fromEntity(
    BookingAvailability availability,
  ) : _availability = availability;

  BookingAvailability toEntity() => _availability;

  factory BookingAvailabilityModel.fromCalendar({
    required String hotelId,
    required RoomEntity room,
    required BookingDates dates,
    required Map<String, dynamic> calendar,
  }) {
    if (room.validate() != null) {
      throw const FormatException(
        'The room category has invalid details.',
      );
    }

    final rawCounts = calendar['counts'];

    if (rawCounts is! Map) {
      throw const FormatException(
        'The availability calendar has an invalid format.',
      );
    }

    final counts = Map<String, dynamic>.from(rawCounts);

    var availableRooms = room.totalRooms;

    for (var offset = 0; offset < dates.nights; offset++) {
      final night = dates.checkInDate.add(
        Duration(days: offset),
      );

      final key = dayKey(night);

      // A missing date means no confirmed reservations that night.
      final Object? reserved =
          counts.containsKey(key) ? counts[key] : 0;

      if (reserved is! int ||
          reserved < 0 ||
          reserved > room.totalRooms) {
        throw const FormatException(
          'The availability calendar contains an invalid room count.',
        );
      }

      final freeRooms = room.totalRooms - reserved;

      if (freeRooms < availableRooms) {
        availableRooms = freeRooms;
      }
    }

    return BookingAvailabilityModel.fromEntity(
      BookingAvailability(
        hotelId: hotelId,
        room: room,
        dates: dates,
        availableRooms: availableRooms,
      ),
    );
  }

  // A consistent calendar key, such as "2026-10-10".
  static String dayKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}