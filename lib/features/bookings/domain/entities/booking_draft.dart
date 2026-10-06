import 'package:equatable/equatable.dart';
import 'package:tala_trip_app/features/rooms/domain/entities/room_entity.dart';

import 'booking_dates.dart';

class BookingDraft extends Equatable {
  final String hotelId;
  final RoomType roomType;
  final BookingDates dates;
  final int guests;

  // The nightly price the traveler saw and reviewed.
  final int reviewedNightlyPriceInCentimes;

  const BookingDraft({
    required this.hotelId,
    required this.roomType,
    required this.dates,
    required this.guests,
    required this.reviewedNightlyPriceInCentimes,
  });

  int get nights => dates.nights;

  int get reviewedTotalPriceInCentimes =>
      reviewedNightlyPriceInCentimes * nights;

  @override
  List<Object?> get props => [
    hotelId,
    roomType,
    dates,
    guests,
    reviewedNightlyPriceInCentimes,
  ];
}