import 'package:tala_trip_app/features/rooms/domain/entities/room_entity.dart';

import '../entities/booking_draft.dart';

class BookingValidation {
  // Check raw dates before creating a BookingDates object.
  static String? validateDates({
    required DateTime checkInDate,
    required DateTime checkOutDate,
    required DateTime todayInAlgeria,
  }) {
    final checkIn = _dateOnly(checkInDate);
    final checkOut = _dateOnly(checkOutDate);
    final today = _dateOnly(todayInAlgeria);

    if (!checkIn.isAfter(today)) {
      return 'Check-in must be tomorrow or later.';
    }

    final latestCheckIn = today.add(const Duration(days: 365));

    if (checkIn.isAfter(latestCheckIn)) {
      return 'Check-in must be within the next 365 days.';
    }

    final nights = checkOut.difference(checkIn).inDays;

    if (nights < 1) {
      return 'Check-out must be after check-in.';
    }

    if (nights > 7) {
      return 'A stay cannot exceed 7 nights.';
    }

    return null;
  }

  // Check the complete draft against the selected room category.
  static String? validateDraft({
    required BookingDraft draft,
    required RoomEntity room,
    required DateTime todayInAlgeria,
  }) {
    if (draft.hotelId.trim().isEmpty) {
      return 'Please select a hotel.';
    }

    final dateError = validateDates(
      checkInDate: draft.dates.checkInDate,
      checkOutDate: draft.dates.checkOutDate,
      todayInAlgeria: todayInAlgeria,
    );

    if (dateError != null) {
      return dateError;
    }

    if (room.validate() != null) {
      return 'This room category has invalid details. Please reload.';
    }

    if (draft.roomType != room.type) {
      return 'The selected room category does not match. Please reload.';
    }

    if (draft.guests < 1) {
      return 'Enter at least one guest.';
    }

    if (draft.guests > room.capacity) {
      return 'This room accommodates up to ${room.capacity} guests.';
    }

    if (draft.reviewedNightlyPriceInCentimes <= 0) {
      return 'Please reload the room price.';
    }

    if (draft.reviewedNightlyPriceInCentimes != room.priceInCentimes) {
      return 'The room price changed. Review the new total before submitting.';
    }

    return null;
  }

  // Represent a calendar date without its hours or minutes.
  static DateTime _dateOnly(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }
}
