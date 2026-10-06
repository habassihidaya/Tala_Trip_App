import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tala_trip_app/features/rooms/domain/entities/room_entity.dart';

import '../../domain/entities/booking_dates.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/entities/booking_status.dart';

class BookingModel {
  final BookingEntity _booking;

  const BookingModel.fromEntity(BookingEntity booking)
      : _booking = booking;

  BookingEntity toEntity() => _booking;

  factory BookingModel.fromJson(
    String documentId,
    Map<String, dynamic> json,
  ) {
    return BookingModel.fromEntity(
      BookingEntity(
        id: documentId,
        requestId: json['requestId'] as String,
        travelerId: json['travelerId'] as String,
        ownerId: json['ownerId'] as String,
        hotelId: json['hotelId'] as String,
        travelerName: json['travelerName'] as String,
        travelerPhone: json['travelerPhone'] as String,
        hotelName: json['hotelName'] as String,
        hotelAddress: json['hotelAddress'] as String,
        hotelPhone: json['hotelPhone'] as String,
        roomType: RoomType.values.byName(
          json['roomType'] as String,
        ),
        capacityAtBooking: json['capacityAtBooking'] as int,
        guests: json['guests'] as int,
        dates: BookingDates(
          checkInDate: _readDate(json['checkInDate']),
          checkOutDate: _readDate(json['checkOutDate']),
        ),
        nightlyPriceInCentimes:
            json['nightlyPriceInCentimes'] as int,
        totalPriceInCentimes:
            json['totalPriceInCentimes'] as int,
        currency: json['currency'] as String,
        status: BookingStatus.values.byName(
          json['status'] as String,
        ),
        createdAt: _readDate(json['createdAt']),
        updatedAt: _readDate(json['updatedAt']),
        checkInStartsAt: _readDate(json['checkInStartsAt']),
        decidedAt: _readOptionalDate(json['decidedAt']),
        decidedBy: json['decidedBy'] as String?,
        rejectionReason: json['rejectionReason'] as String?,
        cancelledAt: _readOptionalDate(json['cancelledAt']),
        cancelledBy: json['cancelledBy'] as String?,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final booking = _booking;

    return {
      'id': booking.id,
      'requestId': booking.requestId,
      'travelerId': booking.travelerId,
      'ownerId': booking.ownerId,
      'hotelId': booking.hotelId,
      'travelerName': booking.travelerName,
      'travelerPhone': booking.travelerPhone,
      'hotelName': booking.hotelName,
      'hotelAddress': booking.hotelAddress,
      'hotelPhone': booking.hotelPhone,
      'roomType': booking.roomType.name,
      'capacityAtBooking': booking.capacityAtBooking,
      'guests': booking.guests,
      'checkInDate': Timestamp.fromDate(
        booking.dates.checkInDate,
      ),
      'checkOutDate': Timestamp.fromDate(
        booking.dates.checkOutDate,
      ),
      'nightlyPriceInCentimes': booking.nightlyPriceInCentimes,
      'totalPriceInCentimes': booking.totalPriceInCentimes,
      'currency': booking.currency,
      'status': booking.status.name,
      'createdAt': Timestamp.fromDate(booking.createdAt),
      'updatedAt': Timestamp.fromDate(booking.updatedAt),
      'checkInStartsAt': Timestamp.fromDate(
        booking.checkInStartsAt,
      ),
      'decidedAt': _writeOptionalDate(booking.decidedAt),
      'decidedBy': booking.decidedBy,
      'rejectionReason': booking.rejectionReason,
      'cancelledAt': _writeOptionalDate(booking.cancelledAt),
      'cancelledBy': booking.cancelledBy,
    };
  }

  static DateTime _readDate(Object? value) {
    if (value is! Timestamp) {
      throw const FormatException(
        'A booking date is missing or has an invalid format.',
      );
    }

    return value.toDate().toUtc();
  }

  static DateTime? _readOptionalDate(Object? value) {
    return value == null ? null : _readDate(value);
  }

  static Timestamp? _writeOptionalDate(DateTime? value) {
    return value == null ? null : Timestamp.fromDate(value);
  }
}