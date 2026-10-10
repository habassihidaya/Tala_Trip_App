import 'package:tala_trip_app/features/rooms/domain/entities/room_entity.dart';

import '../../domain/entities/booking_dates.dart';
import '../../domain/entities/booking_submission.dart';
import '../models/booking_availability_model.dart';
import '../models/booking_model.dart';

abstract class BookingDataSource {
  // Return the authenticated user's ID.
  // Throw an exception if nobody is signed in.
  String get currentUserId;

  Future<BookingAvailabilityModel> checkAvailability({
    required String hotelId,
    required RoomType roomType,
    required BookingDates dates,
  });

  // Create the booking transactionally, or return the existing
  // booking for the same submission.
  Future<BookingModel> submitBooking(BookingSubmission submission);

  // Return the existing booking if found.
  //
  // Return null ONLY after confirming that this request ID
  // is permanently closed and cannot create a booking.
  //
  // Connection errors must throw, never return null.
  Future<BookingModel?> resolveSubmission(BookingSubmission submission);

  Future<List<BookingModel>> getMyBookings();

  Future<List<BookingModel>> getOwnerBookings();

  Future<BookingModel> getBookingById(String bookingId);

  // Update the booking and reserve its nights atomically.
  Future<BookingModel> acceptBooking(String bookingId);

  Future<BookingModel> rejectBooking({
    required String bookingId,
    required String reason,
  });

  // Release reserved nights atomically when cancelling
  // a confirmed booking.
  Future<BookingModel> cancelBooking(String bookingId);
}
