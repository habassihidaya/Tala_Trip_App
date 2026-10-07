import '../../domain/entities/booking_dates.dart';
import '../../domain/entities/booking_submission.dart';
import 'package:tala_trip_app/features/rooms/domain/entities/room_entity.dart';

import '../models/booking_availability_model.dart';
import '../models/booking_model.dart';
import 'booking_data_source.dart';
import 'firebase_booking_actions.dart';
import 'firebase_booking_availability.dart';
import 'firebase_booking_reader.dart';
import 'firebase_booking_recovery.dart';
import 'firebase_booking_submitter.dart';

class FirebaseBookingDataSource implements BookingDataSource {
  final FirebaseBookingReader _reader;
  final FirebaseBookingAvailability _availability;
  final FirebaseBookingSubmitter _submitter;
  final FirebaseBookingRecovery _recovery;
  final FirebaseBookingActions _actions;

  FirebaseBookingDataSource({
  required this._reader,
  required this._availability,
  required this._submitter,
  required this._recovery,
  required this._actions,
});

  @override
  String get currentUserId => _reader.currentUserId;

  @override
  Future<BookingAvailabilityModel> checkAvailability({
    required String hotelId,
    required RoomType roomType,
    required BookingDates dates,
  }) {
    return _availability.checkAvailability(
      hotelId: hotelId,
      roomType: roomType,
      dates: dates,
    );
  }

  @override
  Future<BookingModel> submitBooking(
    BookingSubmission submission,
  ) {
    return _submitter.submitBooking(submission);
  }

  @override
  Future<BookingModel?> resolveSubmission(
    BookingSubmission submission,
  ) {
    return _recovery.resolveSubmission(submission);
  }

  @override
  Future<List<BookingModel>> getMyBookings() {
    return _reader.getMyBookings();
  }

  @override
  Future<List<BookingModel>> getOwnerBookings() {
    return _reader.getOwnerBookings();
  }

  @override
  Future<BookingModel> getBookingById(String bookingId) {
    return _reader.getBookingById(bookingId);
  }

  @override
  Future<BookingModel> acceptBooking(String bookingId) {
    return _actions.acceptBooking(bookingId);
  }

  @override
  Future<BookingModel> rejectBooking({
    required String bookingId,
    required String reason,
  }) {
    return _actions.rejectBooking(
      bookingId: bookingId,
      reason: reason,
    );
  }

  @override
  Future<BookingModel> cancelBooking(String bookingId) {
    return _actions.cancelBooking(bookingId);
  }
}