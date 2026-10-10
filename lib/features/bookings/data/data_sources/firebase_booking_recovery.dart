import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:tala_trip_app/core/errors/booking_exceptions.dart';
import 'package:tala_trip_app/core/errors/exceptions.dart';

import '../../domain/entities/booking_submission.dart';
import '../models/booking_model.dart';
import 'firebase_booking_reader.dart';

class FirebaseBookingRecovery {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseBookingReader _reader;

  FirebaseBookingRecovery(this._auth, this._firestore, this._reader);

  Future<BookingModel?> resolveSubmission(BookingSubmission submission) async {
    _checkAccount(submission.travelerId);

    if (!RegExp(r'^[0-9a-f]{32}$').hasMatch(submission.requestId)) {
      throw const BookingOperationException(
        'The saved request identifier is invalid.',
      );
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

    try {
      final bookingExists = await _firestore.runTransaction<bool>((
        transaction,
      ) async {
        // Read everything before making any write.
        final profileSnapshot = await transaction.get(profileReference);
        final requestSnapshot = await transaction.get(requestReference);
        final bookingSnapshot = await transaction.get(bookingReference);

        _checkAccount(submission.travelerId);

        final profile = profileSnapshot.data();

        if (profile == null || profile['role'] != 'traveler') {
          throw const BookingOperationException(
            'A traveler account is required to recover this request.',
          );
        }

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

            return false;
          }

          if (requestData['status'] != 'recorded' || bookingData == null) {
            throw const FormatException(
              'The booking request record is inconsistent.',
            );
          }

          final model = BookingModel.fromJson(bookingSnapshot.id, bookingData);

          _validateBooking(model, submission);

          return true;
        }

        // Submission must create its request record and booking
        // atomically. One without the other is inconsistent.
        if (bookingData != null) {
          throw const FormatException(
            'A booking exists without its request record.',
          );
        }

        // Close this ID permanently.
        // A competing submission must use this same document,
        // so it cannot commit unnoticed after this closure.
        transaction.set(requestReference, {
          'requestId': submission.requestId,
          'travelerId': submission.travelerId,
          'bookingId': submission.requestId,
          'status': 'closed',
          'createdAt': FieldValue.serverTimestamp(),
        });

        return false;
      }, maxAttempts: 1);

      _checkAccount(submission.travelerId);

      if (!bookingExists) {
        return null;
      }

      final model = await _reader.getBookingById(submission.requestId);

      _checkAccount(submission.travelerId);
      _validateBooking(model, submission);

      return model;
    } on BookingOperationException {
      rethrow;
    } on UnauthenticatedException {
      rethrow;
    } catch (_) {
      // A failed check is not proof that no booking exists.
      throw BookingOutcomeUnknownException(
        operationId: submission.requestId,
        message:
            'We could not resolve your previous request. '
            'Please check it again before submitting another.',
      );
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
        'Please verify your email before checking this request.',
      );
    }
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
        'The recovered booking does not match the saved submission.',
      );
    }
  }
}
