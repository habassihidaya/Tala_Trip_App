import 'dart:math';

import 'package:fpdart/fpdart.dart';
import 'package:tala_trip_app/core/errors/booking_exceptions.dart';
import 'package:tala_trip_app/core/errors/failure_mapper.dart';
import 'package:tala_trip_app/core/errors/failures.dart';
import 'package:tala_trip_app/features/rooms/domain/entities/room_entity.dart';

import '../../domain/entities/booking_availability.dart';
import '../../domain/entities/booking_dates.dart';
import '../../domain/entities/booking_draft.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/entities/booking_submission.dart';
import '../../domain/entities/booking_submission_resolution.dart';
import '../../domain/repositories/booking_repository.dart';
import '../data_sources/booking_data_source.dart';
import '../data_sources/booking_submission_local_data_source.dart';
import '../models/booking_submission_model.dart';

class BookingRepositoryImpl implements BookingRepository {
  final BookingDataSource _remote;
  final BookingSubmissionLocalDataSource _local;
  final Random _random = Random.secure();

  // Serialize submission-related operations within this instance.
  Future<void> _submissionQueue = Future<void>.value();

  BookingRepositoryImpl(this._remote, this._local);

  @override
  Future<Either<Failure, BookingAvailability>> checkAvailability({
    required String hotelId,
    required RoomType roomType,
    required BookingDates dates,
  }) {
    return _execute(() async {
      final model = await _remote.checkAvailability(
        hotelId: hotelId,
        roomType: roomType,
        dates: dates,
      );

      return model.toEntity();
    });
  }

  @override
  Future<Either<Failure, BookingSubmission>> prepareSubmission(
    BookingDraft draft,
  ) {
    return _serialize(() async {
      final travelerId = _remote.currentUserId;
      final existing = await _readLocal(travelerId);

      // Resolve the previous attempt before preparing another one.
      if (existing.isNotEmpty) {
        throw const BookingOperationException(
          'Please check your previous booking request before submitting another.',
        );
      }

      final submission = BookingSubmission(
        requestId: _newRequestId(),
        travelerId: travelerId,
        draft: draft,
      );

      try {
        await _local.saveSubmission(
          BookingSubmissionModel.fromEntity(submission),
        );
      } catch (_) {
        throw const BookingLocalStorageException(
          'We could not save your request for recovery. '
          'No booking request was sent.',
        );
      }

      return submission;
    });
  }

  @override
  Future<Either<Failure, BookingEntity>> submitBooking(
    BookingSubmission submission,
  ) {
    return _serialize(() async {
      _checkAccount(submission);

      final saved = await _readLocal(submission.travelerId);

      final hasMatchingRecord = saved.any(
        (model) => model.toEntity() == submission,
      );

      if (!hasMatchingRecord) {
        throw const BookingLocalStorageException(
          'The saved recovery record is missing or does not match. '
          'The request was not sent.',
        );
      }

      final model = await _remote.submitBooking(submission);

      // Remote success is authoritative even if local cleanup fails.
      await _tryRemoveLocal(submission);

      return model.toEntity();
    });
  }

  @override
  Future<Either<Failure, BookingSubmissionResolution>> resolveSubmission(
    BookingSubmission submission,
  ) {
    return _serialize<BookingSubmissionResolution>(() async {
      _checkAccount(submission);

      final model = await _remote.resolveSubmission(submission);

      // The remote contract guarantees that null means permanently closed.
      await _tryRemoveLocal(submission);

      if (model == null) {
        return BookingSubmissionClosed(
          requestId: submission.requestId,
        );
      }

      return BookingSubmissionFound(
        booking: model.toEntity(),
      );
    });
  }

  @override
  Future<Either<Failure, List<BookingSubmission>>>
      getUnresolvedSubmissions() {
    return _serialize(() async {
      final travelerId = _remote.currentUserId;
      final models = await _readLocal(travelerId);

      return models
          .map((model) => model.toEntity())
          .toList(growable: false);
    });
  }

  @override
  Future<Either<Failure, List<BookingEntity>>> getMyBookings() {
    return _execute(() async {
      final models = await _remote.getMyBookings();

      return models
          .map((model) => model.toEntity())
          .toList(growable: false);
    });
  }

  @override
  Future<Either<Failure, List<BookingEntity>>> getOwnerBookings() {
    return _execute(() async {
      final models = await _remote.getOwnerBookings();

      return models
          .map((model) => model.toEntity())
          .toList(growable: false);
    });
  }

  @override
  Future<Either<Failure, BookingEntity>> getBookingById(
    String bookingId,
  ) {
    return _execute(() async {
      final model = await _remote.getBookingById(bookingId);
      return model.toEntity();
    });
  }

  @override
  Future<Either<Failure, BookingEntity>> acceptBooking(
    String bookingId,
  ) {
    return _execute(() async {
      final model = await _remote.acceptBooking(bookingId);
      return model.toEntity();
    });
  }

  @override
  Future<Either<Failure, BookingEntity>> rejectBooking({
    required String bookingId,
    required String reason,
  }) {
    return _execute(() async {
      final model = await _remote.rejectBooking(
        bookingId: bookingId,
        reason: reason,
      );

      return model.toEntity();
    });
  }

  @override
  Future<Either<Failure, BookingEntity>> cancelBooking(
    String bookingId,
  ) {
    return _execute(() async {
      final model = await _remote.cancelBooking(bookingId);
      return model.toEntity();
    });
  }

  void _checkAccount(BookingSubmission submission) {
    if (_remote.currentUserId != submission.travelerId) {
      throw const BookingOperationException(
        'This request belongs to another account.',
      );
    }
  }

  String _newRequestId() {
    return List.generate(
      16,
      (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  Future<List<BookingSubmissionModel>> _readLocal(
    String travelerId,
  ) async {
    try {
      return await _local.getSubmissions(travelerId);
    } catch (_) {
      throw const BookingLocalStorageException(
        'We could not read your saved booking requests. '
        'Please try again before submitting a new request.',
      );
    }
  }

  Future<void> _tryRemoveLocal(
    BookingSubmission submission,
  ) async {
    try {
      await _local.removeSubmission(
        travelerId: submission.travelerId,
        requestId: submission.requestId,
      );
    } catch (_) {
      // Keep the known remote outcome.
      // A remaining local record can be safely resolved again later.
    }
  }

  Future<Either<Failure, T>> _execute<T>(
    Future<T> Function() action,
  ) async {
    try {
      return Right<Failure, T>(await action());
    } catch (error) {
      return Left<Failure, T>(
        mapExceptionToFailure(error),
      );
    }
  }

  Future<Either<Failure, T>> _serialize<T>(
    Future<T> Function() action,
  ) {
    final result = _submissionQueue.then(
      (_) => _execute<T>(action),
    );

    _submissionQueue = result.then<void>((_) {});

    return result;
  }
}