import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tala_trip_app/core/validation/international_phone.dart';

import 'package:tala_trip_app/core/errors/booking_exceptions.dart';
import 'package:tala_trip_app/core/errors/exceptions.dart';
import 'package:tala_trip_app/core/time/algeria_time.dart';
import 'package:tala_trip_app/features/rooms/data/models/room_model.dart';

import '../../domain/entities/booking_submission.dart';
import '../../domain/validation/booking_validation.dart';
import '../models/booking_availability_model.dart';
import '../models/booking_model.dart';
import 'firebase_booking_reader.dart';

class FirebaseBookingSubmitter {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseBookingReader _reader;
  final AlgeriaTime _algeriaTime;

  FirebaseBookingSubmitter(
    this._auth,
    this._firestore,
    this._reader,
    this._algeriaTime,
  );

  Future<BookingModel> submitBooking(BookingSubmission submission) async {
    _checkAccount(submission.travelerId);

    if (!RegExp(r'^[0-9a-f]{32}$').hasMatch(submission.requestId)) {
      throw const BookingOperationException(
        'The request identifier is invalid.',
      );
    }

    final draft = submission.draft;

    if (draft.hotelId.trim().isEmpty || draft.hotelId.contains('/')) {
      throw const BookingOperationException('The selected hotel is invalid.');
    }

    final profileReference = _firestore
        .collection('users')
        .doc(submission.travelerId);

    final requestReference = profileReference
        .collection('bookingRequests')
        .doc(submission.requestId);

    final bookingReference = _firestore
        .collection('bookings')
        .doc(submission.requestId);

    final hotelReference = _firestore.collection('hotels').doc(draft.hotelId);

    final calendarReference = hotelReference
        .collection('roomAvailability')
        .doc(draft.roomType.name);

    try {
      await _firestore.runTransaction<void>((transaction) async {
        // Check the request before validating a new reservation.
        final requestSnapshot = await transaction.get(requestReference);

        final bookingSnapshot = await transaction.get(bookingReference);

        _checkAccount(submission.travelerId);

        final requestData = requestSnapshot.data();
        final bookingData = bookingSnapshot.data();

        if (requestData != null) {
          _validateRequestRecord(requestData, submission);

          if (requestData['status'] == 'closed') {
            if (bookingData != null) {
              throw const FormatException(
                'A closed request unexpectedly has a booking.',
              );
            }

            throw const BookingOperationException(
              'This request has been closed. '
              'Check its status before starting another request.',
            );
          }

          if (requestData['status'] != 'recorded' || bookingData == null) {
            throw const FormatException(
              'The booking request record is inconsistent.',
            );
          }

          final existingBooking = BookingModel.fromJson(
            bookingSnapshot.id,
            bookingData,
          );

          _validateBooking(existingBooking, submission);

          // Already submitted: do not create or update anything.
          return;
        }

        if (bookingData != null) {
          throw const FormatException(
            'A booking exists without its request record.',
          );
        }

        // This is a new submission.
        // Complete every read before making any write.
        final profileSnapshot = await transaction.get(profileReference);

        final hotelSnapshot = await transaction.get(hotelReference);

        final calendarSnapshot = await transaction.get(calendarReference);

        _checkAccount(submission.travelerId);

        final profile = profileSnapshot.data();
        final hotel = hotelSnapshot.data();

        if (profile == null || profile['role'] != 'traveler') {
          throw const BookingOperationException(
            'A traveler account is required to request a room.',
          );
        }

        if (hotel == null || hotel['status'] != 'approved') {
          throw const BookingOperationException(
            'This hotel is not currently available for booking.',
          );
        }

        final rooms = hotel['rooms'];

        if (rooms is! Map) {
          throw const BookingOperationException(
            'This hotel has no bookable rooms.',
          );
        }

        final roomData = rooms[draft.roomType.name];

        if (roomData is! Map) {
          throw const BookingOperationException(
            'This room type is no longer available.',
          );
        }

        final room = RoomModel.fromJson(
          draft.roomType.name,
          Map<String, dynamic>.from(roomData),
        ).toEntity();

        final validationMessage = BookingValidation.validateDraft(
          draft: draft,
          room: room,
          todayInAlgeria: _algeriaTime.today(now: DateTime.now()),
        );

        if (validationMessage != null) {
          throw BookingOperationException(validationMessage);
        }

        final calendarData = calendarSnapshot.data();

        if (calendarSnapshot.exists && calendarData == null) {
          throw const FormatException('The room availability data is invalid.');
        }

        final availability = BookingAvailabilityModel.fromCalendar(
          hotelId: draft.hotelId,
          room: room,
          dates: draft.dates,
          calendar:
              calendarData ?? <String, dynamic>{'counts': <String, dynamic>{}},
        ).toEntity();

        if (!availability.hasAvailability) {
          throw const BookingOperationException(
            'There are no available rooms for these dates.',
          );
        }

        final travelerName = _requiredText(
          profile['username'],
          'Please add your name to your profile.',
        );

        final travelerPhone = _requiredText(
          profile['mobileNumber'],
          'Please add your phone number to your profile.',
        );

        if (!InternationalPhone.isValid(travelerPhone)) {
          throw const BookingOperationException(
            'Please add a valid international phone number '
            'to your profile.',
          );
        }

        final ownerId = _requiredText(
          hotel['ownerId'],
          'The hotel owner information is missing.',
        );

        final hotelName = _requiredText(
          hotel['name'],
          'The hotel name is missing.',
        );

        final hotelAddress = _requiredText(
          hotel['address'],
          'The hotel address is missing.',
        );

        final hotelPhone = _requiredText(
          hotel['phoneNumber'],
          'The hotel phone number is missing.',
        );

        // Final account check before scheduling the writes.
        _checkAccount(submission.travelerId);

        transaction.set(bookingReference, {
          'id': submission.requestId,
          'requestId': submission.requestId,
          'travelerId': submission.travelerId,
          'ownerId': ownerId,
          'hotelId': draft.hotelId,
          'travelerName': travelerName,
          'travelerPhone': travelerPhone,
          'hotelName': hotelName,
          'hotelAddress': hotelAddress,
          'hotelPhone': hotelPhone,
          'roomType': room.type.name,
          'capacityAtBooking': room.capacity,
          'guests': draft.guests,
          'checkInDate': Timestamp.fromDate(draft.dates.checkInDate),
          'checkOutDate': Timestamp.fromDate(draft.dates.checkOutDate),
          'nightlyPriceInCentimes': room.priceInCentimes,
          'totalPriceInCentimes': room.priceInCentimes * draft.dates.nights,
          'currency': 'DZD',
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'checkInStartsAt': Timestamp.fromDate(
            _algeriaTime.startOfDayUtc(draft.dates.checkInDate),
          ),
          'decidedAt': null,
          'decidedBy': null,
          'rejectionReason': null,
          'cancelledAt': null,
          'cancelledBy': null,
        });

        transaction.set(requestReference, {
          'requestId': submission.requestId,
          'travelerId': submission.travelerId,
          'bookingId': submission.requestId,
          'status': 'recorded',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Pending requests do not reserve inventory.
        // Availability will be checked again on acceptance.
      }, maxAttempts: 1);
    } on BookingOperationException {
      rethrow;
    } on UnauthenticatedException {
      rethrow;
    } catch (_) {
      // A network error is not proof that the booking was not saved.
      throw _unknownOutcome(submission.requestId);
    }

    try {
      // Read the saved booking with its real server timestamps.
      final model = await _reader.getBookingById(submission.requestId);

      _checkAccount(submission.travelerId);
      _validateBooking(model, submission);

      return model;
    } catch (_) {
      // The transaction may have succeeded even if this read fails.
      throw _unknownOutcome(submission.requestId);
    }
  }

  void _checkAccount(String travelerId) {
    final user = _auth.currentUser;

    if (user == null) {
      throw const UnauthenticatedException();
    }

    if (user.uid != travelerId) {
      throw const BookingOperationException(
        'This request belongs to another account.',
      );
    }

    if (!user.emailVerified) {
      throw const BookingOperationException(
        'Please verify your email before requesting a room.',
      );
    }
  }

  String _requiredText(Object? value, String message) {
    if (value is! String || value.trim().isEmpty) {
      throw BookingOperationException(message);
    }

    return value.trim();
  }

  void _validateRequestRecord(
    Map<String, dynamic> data,
    BookingSubmission submission,
  ) {
    if (data['requestId'] != submission.requestId ||
        data['travelerId'] != submission.travelerId ||
        data['bookingId'] != submission.requestId) {
      throw const FormatException(
        'The request record identifiers do not match.',
      );
    }
  }

  void _validateBooking(BookingModel model, BookingSubmission submission) {
    final booking = model.toEntity();
    final draft = submission.draft;

    if (booking.id != submission.requestId ||
        booking.requestId != submission.requestId ||
        booking.travelerId != submission.travelerId ||
        booking.hotelId != draft.hotelId ||
        booking.roomType != draft.roomType ||
        booking.dates != draft.dates ||
        booking.guests != draft.guests ||
        booking.nightlyPriceInCentimes !=
            draft.reviewedNightlyPriceInCentimes ||
        booking.totalPriceInCentimes != draft.reviewedTotalPriceInCentimes ||
        booking.currency != 'DZD') {
      throw const FormatException(
        'The booking does not match the saved submission.',
      );
    }
  }

  BookingOutcomeUnknownException _unknownOutcome(String requestId) {
    return BookingOutcomeUnknownException(
      operationId: requestId,
      message:
          'We could not confirm the result of your request. '
          'Check its status before submitting another.',
    );
  }
}
