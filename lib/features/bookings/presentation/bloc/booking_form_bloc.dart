import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tala_trip_app/core/errors/booking_failures.dart';
import 'package:tala_trip_app/core/network/network_info.dart';
import 'package:tala_trip_app/core/time/algeria_time.dart';
import 'package:tala_trip_app/features/rooms/domain/entities/room_entity.dart';

import '../../domain/entities/booking_availability.dart';
import '../../domain/entities/booking_dates.dart';
import '../../domain/entities/booking_draft.dart';
import '../../domain/entities/booking_submission_resolution.dart';
import '../../domain/usecases/booking_usecases.dart';
import '../../domain/validation/booking_validation.dart';

import 'booking_form_event.dart';
import 'booking_form_state.dart';

class BookingFormBloc
    extends Bloc<BookingFormEvent, BookingFormState> {
  final String _hotelId;
  final RoomType _roomType;

  final CheckBookingAvailability _checkAvailability;
  final PrepareBookingSubmission _prepareSubmission;
  final SubmitBooking _submitBooking;
  final ResolveBookingSubmission _resolveSubmission;
  final GetUnresolvedBookingSubmissions _getUnresolvedSubmissions;

  final NetworkInfo _networkInfo;
  final AlgeriaTime _algeriaTime;

      BookingFormBloc({
    required this._hotelId,
    required this._roomType,
    required this._checkAvailability,
    required this._prepareSubmission,
    required this._submitBooking,
    required this._resolveSubmission,
    required this._getUnresolvedSubmissions,
    required this._networkInfo,
    required this._algeriaTime,
  }) : super(BookingFormState()) {
    on<BookingFormStarted>(_onStarted);
    on<BookingFormDetailsChanged>(_onDetailsChanged);
    on<BookingFormAvailabilityRequested>(_onAvailabilityRequested);
    on<BookingFormSubmitted>(_onSubmitted);
    on<BookingFormRecoveryRequested>(_onRecoveryRequested);
  }

  Future<void> _onStarted(
    BookingFormStarted event,
    Emitter<BookingFormState> emit,
  ) async {
    if (state.isBusy ||
        state.status == BookingFormStatus.submitted) {
      return;
    }

    emit(
      state.copyWith(
        status: BookingFormStatus.loading,
        recoveryChecked: false,
        clearAvailability: true,
        clearMessage: true,
      ),
    );

    // Read local records only. Do not send any booking.
    final result = await _getUnresolvedSubmissions();

    if (_stopped(emit)) return;

    result.fold<void>(
      (failure) {
        emit(
          state.copyWith(
            status: BookingFormStatus.failure,
            recoveryChecked: false,
            message: failure.message,
          ),
        );
      },
      (submissions) {
        var nextState = state.copyWith(
          recoveryChecked: true,
          unresolvedSubmissions: submissions,
          clearMessage: true,
        );

        if (submissions.isEmpty) {
          emit(
            nextState.copyWith(
              status: BookingFormStatus.editing,
            ),
          );
          return;
        }

        final previous = submissions.first;
        final draft = previous.draft;

        final belongsToThisRoom =
            draft.hotelId == _hotelId &&
            draft.roomType == _roomType;

        if (belongsToThisRoom) {
          nextState = nextState.copyWith(
            checkInDate: draft.dates.checkInDate,
            checkOutDate: draft.dates.checkOutDate,
            guests: draft.guests,
          );
        }

        emit(
          nextState.copyWith(
            status: BookingFormStatus.uncertain,
            message: belongsToThisRoom
                ? 'A previous submission needs checking. '
                      'Check its result before submitting again.'
                : 'A previous submission for another room or hotel '
                      'needs checking before you can send a new request.',
          ),
        );
      },
    );
  }

  void _onDetailsChanged(
    BookingFormDetailsChanged event,
    Emitter<BookingFormState> emit,
  ) {
    if (!state.canEdit) return;

    emit(
      state.copyWith(
        status: BookingFormStatus.editing,
        checkInDate: event.checkInDate,
        checkOutDate: event.checkOutDate,
        guests: event.guests,
        clearCheckInDate: event.checkInDate == null,
        clearCheckOutDate: event.checkOutDate == null,
        clearAvailability: true,
        clearBooking: true,
        clearMessage: true,
      ),
    );
  }

  Future<void> _onAvailabilityRequested(
    BookingFormAvailabilityRequested event,
    Emitter<BookingFormState> emit,
  ) async {
    if (!state.canEdit) return;

    final error = _validateInputs();

    if (error != null) {
      _showFailure(emit, error);
      return;
    }

    final dates = BookingDates(
      checkInDate: state.checkInDate!,
      checkOutDate: state.checkOutDate!,
    );

    // Set busy before awaiting anything.
    emit(
      state.copyWith(
        status: BookingFormStatus.checkingAvailability,
        clearAvailability: true,
        clearMessage: true,
      ),
    );

    final result = await _checkAvailability(
      hotelId: _hotelId,
      roomType: _roomType,
      dates: dates,
    );

    if (_stopped(emit)) return;

    result.fold<void>(
      (failure) => _showFailure(emit, failure.message),
      (availability) {
        if (availability.hotelId != _hotelId ||
            availability.room.type != _roomType ||
            availability.dates != dates) {
          _showFailure(
            emit,
            'The availability result does not match this stay. '
            'Please check again.',
          );
          return;
        }

        final draft = _draftFrom(availability);
        final draftError = BookingValidation.validateDraft(
          draft: draft,
          room: availability.room,
          todayInAlgeria: _today(),
        );

        if (draftError != null) {
          _showFailure(emit, draftError);
          return;
        }

        if (!availability.hasAvailability) {
          _showFailure(
            emit,
            'No rooms of this type are available '
            'for the selected dates.',
          );
          return;
        }

        emit(
          state.copyWith(
            status: BookingFormStatus.ready,
            availability: availability,
            clearMessage: true,
          ),
        );
      },
    );
  }

  Future<void> _onSubmitted(
    BookingFormSubmitted event,
    Emitter<BookingFormState> emit,
  ) async {
    if (!state.canSubmit) return;

    final availability = state.availability!;
    final draft = _draftFrom(availability);

    // Validate again in case the form remained open overnight.
    final error = BookingValidation.validateDraft(
      draft: draft,
      room: availability.room,
      todayInAlgeria: _today(),
    );

    if (error != null) {
      _showFailure(emit, error);
      return;
    }

    // Block repeated taps before the network check begins.
    emit(
      state.copyWith(
        status: BookingFormStatus.submitting,
        clearMessage: true,
      ),
    );

    final network = await _networkInfo.checkStatus();

    if (_stopped(emit)) return;

    if (network != NetworkStatus.available) {
      // Nothing has been prepared or submitted.
      // Keep the reviewed form so another deliberate tap is possible.
      emit(
        state.copyWith(
          status: BookingFormStatus.ready,
          message: _networkMessage(network),
        ),
      );
      return;
    }

    // Persist the request ID and details before contacting Firebase.
    final prepared = await _prepareSubmission(draft);

    if (_stopped(emit)) return;

    await prepared.fold<Future<void>>(
      (failure) async {
        // Recheck local storage before allowing another attempt.
        emit(
          state.copyWith(
            status: BookingFormStatus.failure,
            recoveryChecked: false,
            clearAvailability: true,
            message: '${failure.message} '
                'Reload the booking form to check saved requests.',
          ),
        );
      },
      (submission) async {
        emit(
          state.copyWith(
            unresolvedSubmissions: [submission],
          ),
        );

        final result = await _submitBooking(submission);

        if (_stopped(emit)) return;

        result.fold<void>(
          (failure) {
            final unknown =
                failure is BookingOutcomeUnknownFailure;

            emit(
              state.copyWith(
                status: unknown
                    ? BookingFormStatus.uncertain
                    : BookingFormStatus.failure,
                message: '${failure.message} '
                    'Check this request before submitting another.',
              ),
            );
          },
          (booking) {
            emit(
              state.copyWith(
                status: BookingFormStatus.submitted,
                booking: booking,
                unresolvedSubmissions: [],
                clearMessage: true,
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _onRecoveryRequested(
    BookingFormRecoveryRequested event,
    Emitter<BookingFormState> emit,
  ) async {
    if (!state.canRecover) return;

    final submission = state.unresolvedSubmissions.first;

    emit(
      state.copyWith(
        status: BookingFormStatus.recovering,
        clearMessage: true,
      ),
    );

    final network = await _networkInfo.checkStatus();

    if (_stopped(emit)) return;

    if (network != NetworkStatus.available) {
      emit(
        state.copyWith(
          status: BookingFormStatus.uncertain,
          message: network == NetworkStatus.offline
              ? 'You are offline. Reconnect, then check '
                    'your previous request.'
              : 'We could not check your connection. '
                    'Please try checking the request again.',
        ),
      );
      return;
    }

    // This use case finds a booking or closes its unused request ID.
    // It never creates a new booking.
    final result = await _resolveSubmission(submission);

    if (_stopped(emit)) return;

    result.fold<void>(
      (failure) {
        emit(
          state.copyWith(
            status: BookingFormStatus.uncertain,
            message: failure.message,
          ),
        );
      },
      (resolution) {
        final remaining = state.unresolvedSubmissions
            .where(
              (item) => item.requestId != submission.requestId,
            )
            .toList(growable: false);

        switch (resolution) {
          case BookingSubmissionFound(:final booking):
            emit(
              state.copyWith(
                status: remaining.isEmpty
                    ? BookingFormStatus.submitted
                    : BookingFormStatus.uncertain,
                booking: booking,
                unresolvedSubmissions: remaining,
                clearAvailability: true,
                message: remaining.isEmpty
                    ? 'Your previous booking request was found.'
                    : 'A previous booking request was found. '
                          'Other saved requests still need checking.',
              ),
            );

          case BookingSubmissionClosed():
            emit(
              state.copyWith(
                status: remaining.isEmpty
                    ? BookingFormStatus.editing
                    : BookingFormStatus.uncertain,
                unresolvedSubmissions: remaining,
                clearAvailability: true,
                clearBooking: true,
                message: remaining.isEmpty
                    ? 'No booking was created for that request. '
                          'Check availability and review the price '
                          'before submitting again.'
                    : 'That request created no booking. '
                          'Other saved requests still need checking.',
              ),
            );
        }
      },
    );
  }

  String? _validateInputs() {
    final checkIn = state.checkInDate;
    final checkOut = state.checkOutDate;

    if (checkIn == null || checkOut == null) {
      return 'Please select check-in and check-out dates.';
    }

    if (state.guests < 1) {
      return 'Enter at least one guest.';
    }

    return BookingValidation.validateDates(
      checkInDate: checkIn,
      checkOutDate: checkOut,
      todayInAlgeria: _today(),
    );
  }

  BookingDraft _draftFrom(BookingAvailability availability) {
    return BookingDraft(
      hotelId: _hotelId,
      roomType: _roomType,
      dates: availability.dates,
      guests: state.guests,
      reviewedNightlyPriceInCentimes:
          availability.room.priceInCentimes,
    );
  }

  DateTime _today() {
    return _algeriaTime.today(now: DateTime.now());
  }

  String _networkMessage(NetworkStatus network) {
    if (network == NetworkStatus.offline) {
      return 'You are offline. No booking request was sent. '
          'Reconnect, then press Submit again.';
    }

    return 'We could not check your connection. '
        'No booking request was sent. Please try again.';
  }

  void _showFailure(
    Emitter<BookingFormState> emit,
    String message,
  ) {
    emit(
      state.copyWith(
        status: BookingFormStatus.failure,
        clearAvailability: true,
        message: message,
      ),
    );
  }

  bool _stopped(Emitter<BookingFormState> emit) {
    return isClosed || emit.isDone;
  }
}