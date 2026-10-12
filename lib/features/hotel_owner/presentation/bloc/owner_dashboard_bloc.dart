import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import 'package:tala_trip_app/core/errors/failures.dart';
import 'package:tala_trip_app/features/bookings/domain/entities/booking_entity.dart';
import 'package:tala_trip_app/features/bookings/domain/entities/booking_status.dart';
import 'package:tala_trip_app/features/bookings/domain/usecases/booking_usecases.dart';
import 'package:tala_trip_app/features/hotels/domain/entities/hotel_entity.dart';
import 'package:tala_trip_app/features/hotels/domain/usecases/hotel_usecases.dart';

import 'owner_dashboard_event.dart';
import 'owner_dashboard_state.dart';

class OwnerDashboardBloc
    extends Bloc<OwnerDashboardEvent, OwnerDashboardState> {
  final GetMyHotels _getMyHotels;
  final GetOwnerBookings _getOwnerBookings;

  OwnerDashboardBloc({
    required GetMyHotels getMyHotels,
    required GetOwnerBookings getOwnerBookings,
  }) : _getMyHotels = getMyHotels,
       _getOwnerBookings = getOwnerBookings,
       super(const OwnerDashboardInitial()) {
    on<OwnerDashboardRequested>(_onRequested);
  }

  Future<void> _onRequested(
    OwnerDashboardRequested event,
    Emitter<OwnerDashboardState> emit,
  ) async {
    // Ignore additional requests while a load is already running.
    if (state is OwnerDashboardLoading) return;

    emit(const OwnerDashboardLoading());

    try {
      late final Either<Failure, List<HotelEntity>> hotelsResult;
      late final Either<Failure, List<BookingEntity>> bookingsResult;

      // These requests are independent, so start both together.
      await Future.wait<void>([
        _getMyHotels().then<void>((result) {
          hotelsResult = result;
        }),
        _getOwnerBookings().then<void>((result) {
          bookingsResult = result;
        }),
      ]);

      if (emit.isDone) return;

      final errors = <String>[];

      final hotels = hotelsResult.fold<List<HotelEntity>>((failure) {
        errors.add('Hotels: ${failure.message}');
        return const <HotelEntity>[];
      }, (items) => items);

      final bookings = bookingsResult.fold<List<BookingEntity>>((failure) {
        errors.add('Bookings: ${failure.message}');
        return const <BookingEntity>[];
      }, (items) => items);

      // Do not display missing data as a count of zero.
      if (errors.isNotEmpty) {
        emit(OwnerDashboardFailure(errors.join('\n')));
        return;
      }

      final now = DateTime.now().toUtc();

      final pendingRequests = bookings.where((booking) {
        return booking.status == BookingStatus.pending &&
            booking.checkInStartsAt.isAfter(now);
      }).toList();

      // Show requests with the nearest check-in first.
      pendingRequests.sort(
        (first, second) =>
            first.checkInStartsAt.compareTo(second.checkInStartsAt),
      );

      final upcomingBookings = bookings.where((booking) {
        return booking.status == BookingStatus.confirmed &&
            booking.checkInStartsAt.isAfter(now);
      }).toList();

      upcomingBookings.sort(
        (first, second) =>
            first.checkInStartsAt.compareTo(second.checkInStartsAt),
      );

      final sortedHotels = List<HotelEntity>.of(hotels)
        ..sort((first, second) => second.createdAt.compareTo(first.createdAt));

      emit(
        OwnerDashboardLoaded(
          hotels: sortedHotels,
          pendingRequests: pendingRequests,
          upcomingBookings: upcomingBookings,
          loadedAt: now,
        ),
      );
    } catch (_) {
      if (emit.isDone) return;

      emit(
        const OwnerDashboardFailure(
          'The dashboard could not be loaded. Please try again.',
        ),
      );
    }
  }
}
