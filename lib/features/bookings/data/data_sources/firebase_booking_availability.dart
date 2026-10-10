import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:tala_trip_app/core/errors/booking_exceptions.dart';
import 'package:tala_trip_app/core/errors/exceptions.dart';
import 'package:tala_trip_app/core/time/algeria_time.dart';
import 'package:tala_trip_app/features/rooms/data/models/room_model.dart';
import 'package:tala_trip_app/features/rooms/domain/entities/room_entity.dart';

import '../../domain/entities/booking_dates.dart';
import '../../domain/validation/booking_validation.dart';
import '../models/booking_availability_model.dart';

class FirebaseBookingAvailability {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final AlgeriaTime _algeriaTime;

  FirebaseBookingAvailability(this._auth, this._firestore, this._algeriaTime);

  Future<BookingAvailabilityModel> checkAvailability({
    required String hotelId,
    required RoomType roomType,
    required BookingDates dates,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw const UnauthenticatedException();
    }

    if (!user.emailVerified) {
      throw const BookingOperationException(
        'Please verify your email before checking availability.',
      );
    }

    if (hotelId.trim().isEmpty || hotelId.contains('/')) {
      throw const BookingOperationException('Please select a valid hotel.');
    }

    final dateError = BookingValidation.validateDates(
      checkInDate: dates.checkInDate,
      checkOutDate: dates.checkOutDate,
      todayInAlgeria: _algeriaTime.today(now: DateTime.now()),
    );

    if (dateError != null) {
      throw BookingOperationException(dateError);
    }

    final hotelReference = _firestore.collection('hotels').doc(hotelId);

    final calendarReference = hotelReference
        .collection('roomAvailability')
        .doc(roomType.name);

    return _firestore.runTransaction<BookingAvailabilityModel>((
      transaction,
    ) async {
      final hotelSnapshot = await transaction.get(hotelReference);
      final calendarSnapshot = await transaction.get(calendarReference);

      if (_auth.currentUser?.uid != user.uid) {
        throw const UnauthenticatedException();
      }

      final hotel = hotelSnapshot.data();

      if (hotel == null) {
        throw const BookingOperationException('This hotel could not be found.');
      }

      if (hotel['status'] != 'approved') {
        throw const BookingOperationException(
          'This hotel is not currently bookable.',
        );
      }

      final rawRooms = hotel['rooms'];

      if (rawRooms is! Map) {
        throw const BookingOperationException(
          'This hotel has no room categories available.',
        );
      }

      final rawRoom = rawRooms[roomType.name];

      if (rawRoom == null) {
        throw const BookingOperationException(
          'This room category is no longer available.',
        );
      }

      if (rawRoom is! Map) {
        throw const FormatException('The room category has an invalid format.');
      }

      final room = RoomModel.fromJson(
        roomType.name,
        Map<String, dynamic>.from(rawRoom),
      ).toEntity();

      // A successful server read of a missing calendar means
      // this category has no calendar yet.
      //
      // A network or permission error must never become
      // an empty calendar.
      final Map<String, dynamic> calendar;

      if (!calendarSnapshot.exists) {
        calendar = {'counts': <String, dynamic>{}};
      } else {
        final data = calendarSnapshot.data();

        if (data == null) {
          throw const FormatException(
            'The availability calendar could not be read.',
          );
        }

        calendar = data;
      }

      return BookingAvailabilityModel.fromCalendar(
        hotelId: hotelId,
        room: room,
        dates: dates,
        calendar: calendar,
      );
    }, maxAttempts: 1);
  }
}
