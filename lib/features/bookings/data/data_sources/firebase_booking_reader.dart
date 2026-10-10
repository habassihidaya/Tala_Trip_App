import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:tala_trip_app/core/errors/booking_exceptions.dart';
import 'package:tala_trip_app/core/errors/exceptions.dart';

import '../models/booking_model.dart';

class FirebaseBookingReader {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirebaseBookingReader(this._auth, this._firestore);

  String get currentUserId {
    final user = _auth.currentUser;

    if (user == null) {
      throw const UnauthenticatedException();
    }

    return user.uid;
  }

  Future<List<BookingModel>> getMyBookings() async {
    final userId = currentUserId;

    await _requireRole(userId, 'traveler');

    final snapshot = await _firestore
        .collection('bookings')
        .where('travelerId', isEqualTo: userId)
        .get(const GetOptions(source: Source.server));

    _checkAccount(userId);

    return _readAndSort(snapshot);
  }

  Future<List<BookingModel>> getOwnerBookings() async {
    final userId = currentUserId;

    await _requireRole(userId, 'hotelOwner');

    final snapshot = await _firestore
        .collection('bookings')
        .where('ownerId', isEqualTo: userId)
        .get(const GetOptions(source: Source.server));

    _checkAccount(userId);

    return _readAndSort(snapshot);
  }

  Future<BookingModel> getBookingById(String bookingId) async {
    final userId = currentUserId;

    if (bookingId.trim().isEmpty || bookingId.contains('/')) {
      throw const BookingOperationException(
        'The booking identifier is invalid.',
      );
    }

    final snapshot = await _firestore
        .collection('bookings')
        .doc(bookingId)
        .get(const GetOptions(source: Source.server));

    _checkAccount(userId);

    final data = snapshot.data();

    if (data == null) {
      throw const BookingOperationException('This booking could not be found.');
    }

    final model = BookingModel.fromJson(snapshot.id, data);
    final booking = model.toEntity();

    if (booking.travelerId != userId && booking.ownerId != userId) {
      throw const BookingOperationException(
        'You do not have access to this booking.',
      );
    }

    return model;
  }

  Future<void> _requireRole(String userId, String expectedRole) async {
    final user = _auth.currentUser;

    if (user == null || user.uid != userId) {
      throw const UnauthenticatedException();
    }

    if (!user.emailVerified) {
      throw const BookingOperationException(
        'Please verify your email before accessing bookings.',
      );
    }

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .get(const GetOptions(source: Source.server));

    _checkAccount(userId);

    final profile = snapshot.data();

    if (profile == null) {
      throw const UserProfileNotFoundException();
    }

    if (profile['role'] != expectedRole) {
      throw const BookingOperationException(
        'Your account cannot access this booking list.',
      );
    }
  }

  void _checkAccount(String expectedUserId) {
    if (_auth.currentUser?.uid != expectedUserId) {
      throw const UnauthenticatedException();
    }
  }

  List<BookingModel> _readAndSort(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final bookings = snapshot.docs
        .map((document) => BookingModel.fromJson(document.id, document.data()))
        .toList();

    bookings.sort(
      (first, second) =>
          second.toEntity().createdAt.compareTo(first.toEntity().createdAt),
    );

    return bookings;
  }
}
