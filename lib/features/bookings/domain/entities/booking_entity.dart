import 'package:equatable/equatable.dart';
import 'package:tala_trip_app/features/rooms/domain/entities/room_entity.dart';

import 'booking_dates.dart';
import 'booking_status.dart';

class BookingEntity extends Equatable {
  // Identifiers.
  final String id;
  final String requestId;
  final String travelerId;
  final String ownerId;
  final String hotelId;

  // Details saved when the request is submitted.
  final String travelerName;
  final String travelerPhone;
  final String hotelName;
  final String hotelAddress;
  final String hotelPhone;

  // One unit of this room category.
  final RoomType roomType;
  final int capacityAtBooking;
  final int guests;
  final BookingDates dates;

  // Saved prices, expressed in centimes.
  final int nightlyPriceInCentimes;
  final int totalPriceInCentimes;
  final String currency;

  final BookingStatus status;

  // Server timestamps for the saved request.
  final DateTime createdAt;
  final DateTime updatedAt;

  // Actual instant when check-in day starts in Algeria.
  // Acceptance and traveler cancellation must happen before this.
  final DateTime checkInStartsAt;

  // Owner's acceptance or rejection.
  final DateTime? decidedAt;
  final String? decidedBy;
  final String? rejectionReason;

  // Traveler's cancellation.
  final DateTime? cancelledAt;
  final String? cancelledBy;

  const BookingEntity({
    required this.id,
    required this.requestId,
    required this.travelerId,
    required this.ownerId,
    required this.hotelId,
    required this.travelerName,
    required this.travelerPhone,
    required this.hotelName,
    required this.hotelAddress,
    required this.hotelPhone,
    required this.roomType,
    required this.capacityAtBooking,
    required this.guests,
    required this.dates,
    required this.nightlyPriceInCentimes,
    required this.totalPriceInCentimes,
    required this.currency,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.checkInStartsAt,
    this.decidedAt,
    this.decidedBy,
    this.rejectionReason,
    this.cancelledAt,
    this.cancelledBy,
  });

  int get nights => dates.nights;

  @override
  List<Object?> get props => [
    id,
    requestId,
    travelerId,
    ownerId,
    hotelId,
    travelerName,
    travelerPhone,
    hotelName,
    hotelAddress,
    hotelPhone,
    roomType,
    capacityAtBooking,
    guests,
    dates,
    nightlyPriceInCentimes,
    totalPriceInCentimes,
    currency,
    status,
    createdAt,
    updatedAt,
    checkInStartsAt,
    decidedAt,
    decidedBy,
    rejectionReason,
    cancelledAt,
    cancelledBy,
  ];
}