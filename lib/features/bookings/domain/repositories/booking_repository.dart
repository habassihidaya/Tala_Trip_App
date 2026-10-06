import 'package:fpdart/fpdart.dart';
import 'package:tala_trip_app/core/errors/failures.dart';
import 'package:tala_trip_app/features/rooms/domain/entities/room_entity.dart';

import '../entities/booking_availability.dart';
import '../entities/booking_dates.dart';
import '../entities/booking_draft.dart';
import '../entities/booking_entity.dart';
import '../entities/booking_submission.dart';
import '../entities/booking_submission_resolution.dart';

abstract class BookingRepository {
  // Check availability and obtain the current room price.
  Future<Either<Failure, BookingAvailability>> checkAvailability({
    required String hotelId,
    required RoomType roomType,
    required BookingDates dates,
  });

  // Generate a request ID and save the submission locally.
  // This does not send a booking to Firebase.
  Future<Either<Failure, BookingSubmission>> prepareSubmission(
    BookingDraft draft,
  );

  // Send only after a deliberate traveler action.
  // Repeated attempts must preserve the submission's request ID.
  Future<Either<Failure, BookingEntity>> submitBooking(
    BookingSubmission submission,
  );

  // Find the saved booking or permanently close the request ID.
  // This operation must never create a booking.
  Future<Either<Failure, BookingSubmissionResolution>> resolveSubmission(
    BookingSubmission submission,
  );

  // Restore unresolved submissions for the signed-in account only.
  Future<Either<Failure, List<BookingSubmission>>>
      getUnresolvedSubmissions();

  // Load bookings belonging to the signed-in traveler.
  Future<Either<Failure, List<BookingEntity>>> getMyBookings();

  // Load bookings belonging to the signed-in owner's hotels.
  Future<Either<Failure, List<BookingEntity>>> getOwnerBookings();

  // Load one booking, subject to access permissions.
  Future<Either<Failure, BookingEntity>> getBookingById(
    String bookingId,
  );

  // Confirm and reserve availability atomically.
  Future<Either<Failure, BookingEntity>> acceptBooking(
    String bookingId,
  );

  // Reject a pending request with a reason.
  Future<Either<Failure, BookingEntity>> rejectBooking({
    required String bookingId,
    required String reason,
  });

  // Cancel and release availability when previously confirmed.
  Future<Either<Failure, BookingEntity>> cancelBooking(
    String bookingId,
  );
}