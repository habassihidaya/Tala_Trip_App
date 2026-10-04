import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import 'package:tala_trip_app/core/errors/failures.dart';
import 'package:tala_trip_app/features/hotels/domain/entities/hotel_entity.dart';
import 'package:tala_trip_app/features/hotels/domain/usecases/hotel_usecases.dart';

import 'hotel_event.dart';
import 'hotel_state.dart';

class HotelBloc extends Bloc<HotelEvent, HotelState> {
  final CreateHotelDraft _createHotelDraft;
  final GetMyHotels _getMyHotels;
  final GetHotelById _getHotelById;
  final UpdateHotelDraft _updateHotelDraft;
  final DeleteHotelDraft _deleteHotelDraft;
  final SubmitHotelForReview _submitHotelForReview;
  final GetPendingHotels _getPendingHotels;
  final ApproveHotel _approveHotel;
  final RejectHotel _rejectHotel;
  final GetApprovedHotels _getApprovedHotels;

  HotelBloc({
    required this._createHotelDraft,
    required this._getMyHotels,
    required this._getHotelById,
    required this._updateHotelDraft,
    required this._deleteHotelDraft,
    required this._submitHotelForReview,
    required this._getPendingHotels,
    required this._approveHotel,
    required this._rejectHotel,
    required this._getApprovedHotels,
  })  : super(HotelInitialState()) {
    // Process events one at a time.
    on<HotelEvent>(
      _onEvent,
      transformer: (events, mapper) => events.asyncExpand(mapper),
    );
  }

  Future<void> _onEvent(
    HotelEvent event,
    Emitter<HotelState> emit,
  ) async {
    emit(HotelLoadingState());

    if (event is CreateHotelDraftEvent) {
      final result = await _createHotelDraft(
        name: event.name,
        description: event.description,
        wilaya: event.wilaya,
        address: event.address,
        phoneNumber: event.phoneNumber,
        images: event.images,
        mapUrl: event.mapUrl,
      );

      result.fold<void>(
        (failure) => emit(HotelErrorState(message: failure.message)),
        (hotel) => emit(HotelDraftCreatedState(hotel: hotel)),
      );
      return;
    }

    if (event is GetMyHotelsEvent) {
      final result = await _getMyHotels();
      _emitHotelList(result, emit);
      return;
    }

    if (event is GetHotelByIdEvent) {
      final result = await _getHotelById(event.id);

      result.fold<void>(
        (failure) => emit(HotelErrorState(message: failure.message)),
        (hotel) => emit(HotelDetailsLoadedState(hotel: hotel)),
      );
      return;
    }

    if (event is UpdateHotelDraftEvent) {
      final result = await _updateHotelDraft(event.hotel);

      _emitActionResult(
        result,
        emit,
        hotelId: event.hotel.id,
        action: HotelAction.updated,
      );
      return;
    }

    if (event is DeleteHotelDraftEvent) {
      final result = await _deleteHotelDraft(event.id);

      _emitActionResult(
        result,
        emit,
        hotelId: event.id,
        action: HotelAction.deleted,
      );
      return;
    }

    if (event is SubmitHotelForReviewEvent) {
      final result = await _submitHotelForReview(event.id);

      _emitActionResult(
        result,
        emit,
        hotelId: event.id,
        action: HotelAction.submitted,
      );
      return;
    }

    if (event is GetPendingHotelsEvent) {
      final result = await _getPendingHotels();
      _emitHotelList(result, emit);
      return;
    }

    if (event is ApproveHotelEvent) {
      final result = await _approveHotel(event.id);

      _emitActionResult(
        result,
        emit,
        hotelId: event.id,
        action: HotelAction.approved,
      );
      return;
    }

    if (event is RejectHotelEvent) {
      final reason = event.reason.trim();

      if (reason.isEmpty) {
        emit(
          HotelErrorState(message: 'Please provide a rejection reason.'),
        );
        return;
      }

      final result = await _rejectHotel(event.id, reason);

      _emitActionResult(
        result,
        emit,
        hotelId: event.id,
        action: HotelAction.rejected,
      );
      return;
    }

    if (event is GetApprovedHotelsEvent) {
      final result = await _getApprovedHotels();
      _emitHotelList(result, emit);
      return;
    }

    emit(HotelErrorState(message: 'Unsupported hotel action.'));
  }

  // Shared handling for the three hotel-list operations.
  void _emitHotelList(
    Either<Failure, List<HotelEntity>> result,
    Emitter<HotelState> emit,
  ) {
    result.fold<void>(
      (failure) => emit(HotelErrorState(message: failure.message)),
      (hotels) {
        if (hotels.isEmpty) {
          emit(HotelsEmptyState());
        } else {
          emit(HotelsLoadedState(hotels: hotels));
        }
      },
    );
  }

  // Shared handling for operations that return success without data.
  void _emitActionResult(
    Either<Failure, Unit> result,
    Emitter<HotelState> emit, {
    required String hotelId,
    required HotelAction action,
  }) {
    result.fold<void>(
      (failure) => emit(HotelErrorState(message: failure.message)),
      (_) => emit(
        HotelActionSuccessState(
          hotelId: hotelId,
          action: action,
        ),
      ),
    );
  }
}