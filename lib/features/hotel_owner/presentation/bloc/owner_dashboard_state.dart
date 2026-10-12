import 'package:tala_trip_app/features/bookings/domain/entities/booking_entity.dart';
import 'package:tala_trip_app/features/hotels/domain/entities/hotel_entity.dart';

abstract class OwnerDashboardState {
  const OwnerDashboardState();
}

class OwnerDashboardInitial extends OwnerDashboardState {
  const OwnerDashboardInitial();
}

class OwnerDashboardLoading extends OwnerDashboardState {
  const OwnerDashboardLoading();
}

class OwnerDashboardLoaded extends OwnerDashboardState {
  final List<HotelEntity> hotels;
  final List<BookingEntity> pendingRequests;
  final List<BookingEntity> upcomingBookings;
  final DateTime loadedAt;

  OwnerDashboardLoaded({
    required List<HotelEntity> hotels,
    required List<BookingEntity> pendingRequests,
    required List<BookingEntity> upcomingBookings,
    required this.loadedAt,
  }) : hotels = List<HotelEntity>.unmodifiable(hotels),
       pendingRequests = List<BookingEntity>.unmodifiable(pendingRequests),
       upcomingBookings = List<BookingEntity>.unmodifiable(upcomingBookings);

  int get hotelCount => hotels.length;

  int get pendingRequestCount => pendingRequests.length;

  int get upcomingBookingCount => upcomingBookings.length;

  bool get isEmpty =>
      hotels.isEmpty && pendingRequests.isEmpty && upcomingBookings.isEmpty;
}

class OwnerDashboardFailure extends OwnerDashboardState {
  final String message;

  const OwnerDashboardFailure(this.message);
}
