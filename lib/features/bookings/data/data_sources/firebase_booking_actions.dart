import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:tala_trip_app/core/errors/booking_exceptions.dart';
import 'package:tala_trip_app/core/errors/exceptions.dart';
import 'package:tala_trip_app/core/time/algeria_time.dart';
import 'package:tala_trip_app/features/rooms/data/models/room_model.dart';

import '../../domain/entities/booking_entity.dart';
import '../../domain/entities/booking_status.dart';
import '../models/booking_availability_model.dart';
import '../models/booking_model.dart';
import 'firebase_booking_reader.dart';

class FirebaseBookingActions {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseBookingReader _reader;
  final AlgeriaTime _algeriaTime;

  FirebaseBookingActions(
    this._auth,
    this._firestore,
    this._reader,
    this._algeriaTime,
  );

  Future<BookingModel> acceptBooking(String bookingId) {
    return _changeStatus(
      bookingId: bookingId,
      target: BookingStatus.confirmed,
    );
  }

  Future<BookingModel> rejectBooking({
    required String bookingId,
    required String reason,
  }) async {
    final trimmedReason = reason.trim();

    if (trimmedReason.isEmpty || trimmedReason.length > 1000) {
      throw const BookingOperationException(
        'Please enter a rejection reason of 1 to 1000 characters.',
      );
    }

    return _changeStatus(
      bookingId: bookingId,
      target: BookingStatus.rejected,
      rejectionReason: trimmedReason,
    );
  }

  Future<BookingModel> cancelBooking(String bookingId) {
    return _changeStatus(
      bookingId: bookingId,
      target: BookingStatus.cancelled,
    );
  }

  Future<BookingModel> _changeStatus({
    required String bookingId,
    required BookingStatus target,
    String? rejectionReason,
  }) async {
    final actorId = _verifiedUserId();

    if (!RegExp(r'^[0-9a-f]{32}$').hasMatch(bookingId)) {
      throw const BookingOperationException(
        'The booking identifier is invalid.',
      );
    }

    final bookingReference = _firestore
        .collection('bookings')
        .doc(bookingId);

    final profileReference = _firestore
        .collection('users')
        .doc(actorId);

    try {
      await _firestore.runTransaction<void>(
        (transaction) async {
          final bookingSnapshot = await transaction.get(
            bookingReference,
          );

          final profileSnapshot = await transaction.get(
            profileReference,
          );

          _checkSameAccount(actorId);

          final bookingData = bookingSnapshot.data();

          if (bookingData == null) {
            throw const BookingOperationException(
              'This booking no longer exists.',
            );
          }

          final booking = BookingModel.fromJson(
            bookingSnapshot.id,
            bookingData,
          ).toEntity();

          final profile = profileSnapshot.data();
          final isCancellation = target == BookingStatus.cancelled;

          final hotelReference = _firestore
              .collection('hotels')
              .doc(booking.hotelId);

          Map<String, dynamic>? hotel;

          if (isCancellation) {
            if (profile?['role'] != 'traveler' ||
                booking.travelerId != actorId) {
              throw const BookingOperationException(
                'You can only cancel your own bookings.',
              );
            }

            // Cancellation does not require the hotel to remain
            // published or the room type to remain listed.
          } else {
            if (profile?['role'] != 'hotelOwner' ||
                booking.ownerId != actorId) {
              throw const BookingOperationException(
                'You cannot manage this booking.',
              );
            }

            final hotelSnapshot = await transaction.get(
              hotelReference,
            );

            hotel = hotelSnapshot.data();

            if (hotel == null || hotel['ownerId'] != actorId) {
              throw const BookingOperationException(
                'You do not own the hotel for this booking.',
              );
            }
          }

          // A repeated action must not change inventory again.
          if (booking.status == target) {
            if (target == BookingStatus.rejected &&
                booking.rejectionReason != rejectionReason) {
              throw const BookingOperationException(
                'This booking has already been rejected '
                'with a different reason.',
              );
            }

            return;
          }

          _validateTransition(booking, target);

          final expectedCheckInStart = _algeriaTime.startOfDayUtc(
            booking.dates.checkInDate,
          );

          if (booking.checkInStartsAt != expectedCheckInStart) {
            throw const FormatException(
              'The booking check-in time is inconsistent.',
            );
          }

          if (!DateTime.now().toUtc().isBefore(expectedCheckInStart)) {
            throw const BookingOperationException(
              'This booking can no longer be changed because '
              'its check-in day has started.',
            );
          }

          final isAcceptance = target == BookingStatus.confirmed;

          final releasesInventory =
              isCancellation &&
              booking.status == BookingStatus.confirmed;

          final calendarReference = hotelReference
              .collection('roomAvailability')
              .doc(booking.roomType.name);

          Map<String, dynamic>? calendarUpdate;

          if (isAcceptance || releasesInventory) {
            final calendarSnapshot = await transaction.get(
              calendarReference,
            );

            final calendar = calendarSnapshot.data();

            if (calendarSnapshot.exists && calendar == null) {
              throw const FormatException(
                'The room availability data is invalid.',
              );
            }

            if (releasesInventory && calendar == null) {
              throw const FormatException(
                'A confirmed booking has no availability record.',
              );
            }

            final counts = _readCounts(calendar);

            var lockUntil = _readLockUntil(calendar);

            if (isAcceptance) {
              if (hotel == null || hotel['status'] != 'approved') {
                throw const BookingOperationException(
                  'This hotel is not currently bookable.',
                );
              }

              final rooms = hotel['rooms'];

              if (rooms is! Map) {
                throw const BookingOperationException(
                  'This hotel has no bookable rooms.',
                );
              }

              final roomData = rooms[booking.roomType.name];

              if (roomData is! Map) {
                throw const BookingOperationException(
                  'This room type is no longer available.',
                );
              }

              final room = RoomModel.fromJson(
                booking.roomType.name,
                Map<String, dynamic>.from(roomData),
              ).toEntity();

              final roomError = room.validate();

              if (roomError != null) {
                throw BookingOperationException(roomError);
              }

              if (booking.guests < 1 ||
                  booking.guests > room.capacity) {
                throw const BookingOperationException(
                  'The room no longer accommodates '
                  'the requested number of guests.',
                );
              }

              for (final day in _stayDays(booking)) {
                final reserved = counts[day] ?? 0;

                if (reserved >= room.totalRooms) {
                  throw const BookingOperationException(
                    'There are no available rooms for all '
                    'the requested nights.',
                  );
                }

                counts[day] = reserved + 1;
              }

              final checkoutStart = _algeriaTime.startOfDayUtc(
                booking.dates.checkOutDate,
              );

              if (lockUntil == null ||
                  checkoutStart.isAfter(lockUntil)) {
                lockUntil = checkoutStart;
              }
            } else {
              for (final day in _stayDays(booking)) {
                final reserved = counts[day] ?? 0;

                if (reserved < 1) {
                  throw const FormatException(
                    'The reserved room count is inconsistent.',
                  );
                }

                if (reserved == 1) {
                  counts.remove(day);
                } else {
                  counts[day] = reserved - 1;
                }
              }

              // Keep the conservative room-management lock.
              // Cancelling does not shorten lockUntil.
            }

            if (lockUntil == null) {
              throw const FormatException(
                'The room availability lock is missing.',
              );
            }

            calendarUpdate = {
              'hotelId': booking.hotelId,
              'roomType': booking.roomType.name,
              'counts': counts,
              'lockUntil': Timestamp.fromDate(lockUntil),
              'lastBookingId': booking.id,
              'updatedAt': FieldValue.serverTimestamp(),
            };
          }

          final bookingUpdate = <String, dynamic>{
            'status': target.name,
            'updatedAt': FieldValue.serverTimestamp(),
          };

          if (isCancellation) {
            bookingUpdate.addAll({
              'cancelledAt': FieldValue.serverTimestamp(),
              'cancelledBy': actorId,
            });
          } else {
            bookingUpdate.addAll({
              'decidedAt': FieldValue.serverTimestamp(),
              'decidedBy': actorId,
              'rejectionReason': rejectionReason,
            });
          }

          _checkSameAccount(actorId);

          // All reads are finished. Save both changes together.
          if (calendarUpdate != null) {
            transaction.set(
              calendarReference,
              calendarUpdate,
            );
          }

          transaction.update(
            bookingReference,
            bookingUpdate,
          );
        },
        maxAttempts: 1,
      );
    } on BookingOperationException {
      rethrow;
    } on UnauthenticatedException {
      rethrow;
    } on FormatException {
      rethrow;
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        rethrow;
      }

      throw _unknownOutcome(bookingId);
    } catch (_) {
      throw _unknownOutcome(bookingId);
    }

    try {
      final model = await _reader.getBookingById(bookingId);

      _checkSameAccount(actorId);

      // Return the current server state. Another authorized action
      // may have occurred after our transaction completed.
      return model;
    } catch (_) {
      throw _unknownOutcome(bookingId);
    }
  }

  void _validateTransition(
    BookingEntity booking,
    BookingStatus target,
  ) {
    final allowed = switch (target) {
      BookingStatus.confirmed ||
      BookingStatus.rejected =>
        booking.status == BookingStatus.pending,
      BookingStatus.cancelled =>
        booking.status == BookingStatus.pending ||
            booking.status == BookingStatus.confirmed,
      BookingStatus.pending => false,
    };

    if (!allowed) {
      throw const BookingOperationException(
        'This action is not available for the current booking status. '
        'Refresh the booking to see its latest status.',
      );
    }
  }

  Iterable<String> _stayDays(BookingEntity booking) sync* {
    for (var index = 0; index < booking.dates.nights; index++) {
      final date = booking.dates.checkInDate.add(
        Duration(days: index),
      );

      yield BookingAvailabilityModel.dayKey(date);
    }
  }

  Map<String, int> _readCounts(
    Map<String, dynamic>? calendar,
  ) {
    if (calendar == null) {
      return <String, int>{};
    }

    final rawCounts = calendar['counts'];

    if (rawCounts is! Map) {
      throw const FormatException(
        'The room availability counts are invalid.',
      );
    }

    final counts = <String, int>{};

    for (final entry in rawCounts.entries) {
      final key = entry.key;
      final value = entry.value;

      if (key is! String ||
          !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(key) ||
          value is! int ||
          value < 0 ||
          value > 10000) {
        throw const FormatException(
          'A room availability entry is invalid.',
        );
      }

      counts[key] = value;
    }

    return counts;
  }

  DateTime? _readLockUntil(
    Map<String, dynamic>? calendar,
  ) {
    if (calendar == null) {
      return null;
    }

    final value = calendar['lockUntil'];

    if (value is! Timestamp) {
      throw const FormatException(
        'The room availability lock is invalid.',
      );
    }

    return value.toDate().toUtc();
  }

  String _verifiedUserId() {
    final user = _auth.currentUser;

    if (user == null) {
      throw const UnauthenticatedException();
    }

    if (!user.emailVerified) {
      throw const BookingOperationException(
        'Please verify your email before changing a booking.',
      );
    }

    return user.uid;
  }

  void _checkSameAccount(String expectedUserId) {
    if (_verifiedUserId() != expectedUserId) {
      throw const BookingOperationException(
        'Your account changed. Please reopen the booking.',
      );
    }
  }

  BookingOutcomeUnknownException _unknownOutcome(
    String bookingId,
  ) {
    return BookingOutcomeUnknownException(
      operationId: bookingId,
      message: 'We could not confirm whether the booking changed. '
          'Refresh this booking before trying the action again.',
    );
  }
}