import 'package:fpdart/fpdart.dart';
import 'package:tala_trip_app/core/errors/failures.dart';
import 'package:tala_trip_app/features/rooms/domain/entities/room_entity.dart';

import '../entities/booking_availability.dart';
import '../entities/booking_dates.dart';
import '../entities/booking_draft.dart';
import '../entities/booking_entity.dart';
import '../entities/booking_submission.dart';
import '../entities/booking_submission_resolution.dart';
import '../repositories/booking_repository.dart';

class CheckBookingAvailability {
  final BookingRepository _repository;

  CheckBookingAvailability(this._repository);

  Future<Either<Failure, BookingAvailability>> call({
    required String hotelId,
    required RoomType roomType,
    required BookingDates dates,
  }) {
    return _repository.checkAvailability(
      hotelId: hotelId,
      roomType: roomType,
      dates: dates,
    );
  }
}

class PrepareBookingSubmission {
  final BookingRepository _repository;

  PrepareBookingSubmission(this._repository);

  Future<Either<Failure, BookingSubmission>> call(
    BookingDraft draft,
  ) {
    return _repository.prepareSubmission(draft);
  }
}

class SubmitBooking {
  final BookingRepository _repository;

  SubmitBooking(this._repository);

  Future<Either<Failure, BookingEntity>> call(
    BookingSubmission submission,
  ) {
    return _repository.submitBooking(submission);
  }
}

class ResolveBookingSubmission {
  final BookingRepository _repository;

  ResolveBookingSubmission(this._repository);

  Future<Either<Failure, BookingSubmissionResolution>> call(
    BookingSubmission submission,
  ) {
    return _repository.resolveSubmission(submission);
  }
}

class GetUnresolvedBookingSubmissions {
  final BookingRepository _repository;

  GetUnresolvedBookingSubmissions(this._repository);

  Future<Either<Failure, List<BookingSubmission>>> call() {
    return _repository.getUnresolvedSubmissions();
  }
}

class GetMyBookings {
  final BookingRepository _repository;

  GetMyBookings(this._repository);

  Future<Either<Failure, List<BookingEntity>>> call() {
    return _repository.getMyBookings();
  }
}

class GetOwnerBookings {
  final BookingRepository _repository;

  GetOwnerBookings(this._repository);

  Future<Either<Failure, List<BookingEntity>>> call() {
    return _repository.getOwnerBookings();
  }
}

class GetBookingById {
  final BookingRepository _repository;

  GetBookingById(this._repository);

  Future<Either<Failure, BookingEntity>> call(
    String bookingId,
  ) {
    return _repository.getBookingById(bookingId);
  }
}

class AcceptBooking {
  final BookingRepository _repository;

  AcceptBooking(this._repository);

  Future<Either<Failure, BookingEntity>> call(
    String bookingId,
  ) {
    return _repository.acceptBooking(bookingId);
  }
}

class RejectBooking {
  final BookingRepository _repository;

  RejectBooking(this._repository);

  Future<Either<Failure, BookingEntity>> call({
    required String bookingId,
    required String reason,
  }) {
    final trimmedReason = reason.trim();

    if (trimmedReason.isEmpty) {
      return Future.value(
        const Left<Failure, BookingEntity>(
          ServerFailure('Please enter a rejection reason.'),
        ),
      );
    }

    if (trimmedReason.length > 1000) {
      return Future.value(
        const Left<Failure, BookingEntity>(
          ServerFailure(
            'The rejection reason cannot exceed 1,000 characters.',
          ),
        ),
      );
    }

    return _repository.rejectBooking(
      bookingId: bookingId,
      reason: trimmedReason,
    );
  }
}

class CancelBooking {
  final BookingRepository _repository;

  CancelBooking(this._repository);

  Future<Either<Failure, BookingEntity>> call(
    String bookingId,
  ) {
    return _repository.cancelBooking(bookingId);
  }
}