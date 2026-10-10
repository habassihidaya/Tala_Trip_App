import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/favorites_usecases.dart';
import 'favorites_event.dart';
import 'favorites_state.dart';

class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  final GetFavoriteIds _getFavoriteIds;
  final GetFavoriteHotels _getFavoriteHotels;
  final AddFavorite _addFavorite;
  final RemoveFavorite _removeFavorite;

  FavoritesBloc({
    required this._getFavoriteIds,
    required this._getFavoriteHotels,
    required this._addFavorite,
    required this._removeFavorite,
  }) : super(FavoritesState()) {
    on<FavoritesEvent>(
      _onEvent,
      // Process events in order to avoid conflicting state updates.
      transformer: (events, mapper) => events.asyncExpand(mapper),
    );
  }

  Future<void> _onEvent(
    FavoritesEvent event,
    Emitter<FavoritesState> emit,
  ) async {
    if (event is FavoritesStarted) {
      if (state.idsStatus != FavoritesStatus.success) {
        await _loadIds(emit);
      }
    } else if (event is FavoriteHotelsRequested) {
      await _loadHotels(emit);
    } else if (event is FavoriteToggled) {
      await _toggleFavorite(event, emit);
    }
  }

  Future<void> _loadIds(Emitter<FavoritesState> emit) async {
    emit(
      state.copyWith(idsStatus: FavoritesStatus.loading, clearIdsError: true),
    );

    final result = await _getFavoriteIds();

    if (emit.isDone) {
      return;
    }

    result.fold(
      (failure) => emit(
        state.copyWith(
          idsStatus: FavoritesStatus.failure,
          idsError: failure.message,
        ),
      ),
      (ids) => emit(
        state.copyWith(
          favoriteIds: ids,
          idsStatus: FavoritesStatus.success,
          clearIdsError: true,
        ),
      ),
    );
  }

  Future<void> _loadHotels(Emitter<FavoritesState> emit) async {
    emit(
      state.copyWith(
        hotelsStatus: FavoritesStatus.loading,
        clearHotelsError: true,
        clearActionError: true,
      ),
    );

    if (state.idsStatus != FavoritesStatus.success) {
      await _loadIds(emit);
    }

    if (emit.isDone) {
      return;
    }

    if (state.idsStatus != FavoritesStatus.success) {
      emit(
        state.copyWith(
          hotelsStatus: FavoritesStatus.failure,
          hotelsError: state.idsError ?? 'Could not load your favorites.',
        ),
      );
      return;
    }

    final result = await _getFavoriteHotels();

    if (emit.isDone) {
      return;
    }

    result.fold(
      (failure) => emit(
        state.copyWith(
          hotelsStatus: FavoritesStatus.failure,
          hotelsError: failure.message,
        ),
      ),
      (hotels) => emit(
        state.copyWith(
          hotels: hotels,
          hotelsStatus: FavoritesStatus.success,
          clearHotelsError: true,
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(
    FavoriteToggled event,
    Emitter<FavoritesState> emit,
  ) async {
    if (state.idsStatus != FavoritesStatus.success) {
      emit(
        state.copyWith(
          actionError: 'Please reload your favorites before making changes.',
        ),
      );
      return;
    }

    final hotel = event.hotel;
    final wasFavorite = state.isFavorite(hotel.id);

    emit(
      state.copyWith(
        updatingHotelIds: {...state.updatingHotelIds, hotel.id},
        clearActionError: true,
      ),
    );

    final result = wasFavorite
        ? await _removeFavorite(hotelId: hotel.id)
        : await _addFavorite(hotelId: hotel.id);

    if (emit.isDone) {
      return;
    }

    final updatingIds = {...state.updatingHotelIds}..remove(hotel.id);

    result.fold(
      (failure) => emit(
        state.copyWith(
          updatingHotelIds: updatingIds,
          actionError: failure.message,
        ),
      ),
      (_) {
        final ids = {...state.favoriteIds};
        final hotels = [...state.hotels];

        if (wasFavorite) {
          ids.remove(hotel.id);
          hotels.removeWhere((item) => item.id == hotel.id);
        } else {
          ids.add(hotel.id);

          if (state.hotelsStatus == FavoritesStatus.success &&
              !hotels.any((item) => item.id == hotel.id)) {
            hotels.add(hotel);
          }
        }

        emit(
          state.copyWith(
            favoriteIds: ids,
            hotels: hotels,
            updatingHotelIds: updatingIds,
            clearActionError: true,
          ),
        );
      },
    );
  }
}
