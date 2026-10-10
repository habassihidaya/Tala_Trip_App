import 'package:equatable/equatable.dart';
import 'package:tala_trip_app/features/rooms/domain/entities/room_entity.dart';

import 'booking_dates.dart';

class BookingAvailability extends Equatable {
  final String hotelId;
  final RoomEntity room;
  final BookingDates dates;

  // Number of units available throughout the entire stay.
  final int availableRooms;

  const BookingAvailability({
    required this.hotelId,
    required this.room,
    required this.dates,
    required this.availableRooms,
  });

  bool get hasAvailability => availableRooms > 0;

  int get totalPriceInCentimes => room.priceInCentimes * dates.nights;

  @override
  List<Object?> get props => [hotelId, room, dates, availableRooms];
}
