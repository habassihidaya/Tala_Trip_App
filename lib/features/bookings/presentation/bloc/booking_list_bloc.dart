import 'package:fpdart/fpdart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tala_trip_app/core/errors/failures.dart';

import '../../domain/entities/booking_entity.dart';
import '../../domain/usecases/booking_usecases.dart';

import 'booking_list_event.dart';
import 'booking_list_state.dart';

class BookingListBloc extends Bloc<BookingListEvent, BookingListState> {
  final BookingListAudience _audience;

  final GetMyBookings _getMyBookings;
  final GetOwnerBookings _getOwnerBookings;
  final AcceptBooking _acceptBooking;
  final RejectBooking _rejectBooking;
  final CancelBooking _cancelBooking;

  bool _loading = false;
  final Set<String> _actionIds = {};

  BookingListBloc({
    required this._audience,
    required this._getMyBookings,
    required this._getOwnerBookings,
    required this._acceptBooking,
    required this._rejectBooking,
    required this._cancelBooking,
  }) : super(BookingListState(audience: _audience)) {
    on<BookingListStarted>(_onStarted);
    on<BookingListRefreshRequested>(_onRefresh);
    on<BookingAcceptRequested>(_onAccept);
    on<BookingRejectRequested>(_onReject);
    on<BookingCancelRequested>(_onCancel);
  }

  Future<void> _onStarted(
    BookingListStarted event,
    Emitter<BookingListState> emit,
  ) {
    return _load(emit);
  }

  Future<void> _onRefresh(
    BookingListRefreshRequested event,
    Emitter<BookingListState> emit,
  ) {
    if (state.isBusy) return Future.value();

    return _load(emit);
  }

  Future<void> _load(Emitter<BookingListState> emit) async {
    if (_loading) return;

    _loading = true;

    emit(
      state.copyWith(
        status: BookingListStatus.loading,
        clearMessage: true,
        clearActionBookingId: true,
      ),
    );

    final result = _audience == BookingListAudience.traveler
        ? await _getMyBookings()
        : await _getOwnerBookings();

    if (emit.isDone) {
      _loading = false;
      return;
    }

    result.fold<void>(
      (failure) {
        emit(
          state.copyWith(
            status: BookingListStatus.failure,
            message: failure.message,
          ),
        );
      },
      (bookings) {
        emit(
          state.copyWith(
            status: BookingListStatus.loaded,
            bookings: bookings,
            clearMessage: true,
            clearActionBookingId: true,
          ),
        );
      },
    );

    _loading = false;
  }

  Future<void> _onAccept(
    BookingAcceptRequested event,
    Emitter<BookingListState> emit,
  ) {
    if (_audience != BookingListAudience.owner) {
      return Future.value();
    }

    return _runAction(
      bookingId: event.bookingId,
      action: () => _acceptBooking.call(event.bookingId),
      successMessage: 'Booking request accepted.',
      emit: emit,
    );
  }

  Future<void> _onReject(
    BookingRejectRequested event,
    Emitter<BookingListState> emit,
  ) {
    if (_audience != BookingListAudience.owner) {
      return Future.value();
    }

    return _runAction(
      bookingId: event.bookingId,
      action: () =>
          _rejectBooking(bookingId: event.bookingId, reason: event.reason),
      successMessage: 'Booking request rejected.',
      emit: emit,
    );
  }

  Future<void> _onCancel(
    BookingCancelRequested event,
    Emitter<BookingListState> emit,
  ) {
    if (_audience != BookingListAudience.traveler) {
      return Future.value();
    }

    return _runAction(
      bookingId: event.bookingId,
      action: () => _cancelBooking(event.bookingId),
      successMessage: 'Booking cancelled.',
      emit: emit,
    );
  }

  Future<void> _runAction({
    required String bookingId,
    required Future<Either<Failure, BookingEntity>> Function() action,
    required String successMessage,
    required Emitter<BookingListState> emit,
  }) async {
    if (state.isBusy || _actionIds.contains(bookingId)) {
      return;
    }

    _actionIds.add(bookingId);

    emit(
      state.copyWith(
        status: BookingListStatus.actionLoading,
        actionBookingId: bookingId,
        clearMessage: true,
      ),
    );

    final result = await action();

    if (emit.isDone) {
      _actionIds.remove(bookingId);
      return;
    }

    result.fold<void>(
      (failure) {
        emit(
          state.copyWith(
            status: BookingListStatus.failure,
            clearActionBookingId: true,
            message: failure.message,
          ),
        );
      },
      (updatedBooking) {
        final updatedBookings = state.bookings
            .map((booking) {
              return booking.id == updatedBooking.id ? updatedBooking : booking;
            })
            .toList(growable: false);

        emit(
          state.copyWith(
            status: BookingListStatus.loaded,
            bookings: updatedBookings,
            clearActionBookingId: true,
            message: successMessage,
          ),
        );
      },
    );

    _actionIds.remove(bookingId);
  }
}
