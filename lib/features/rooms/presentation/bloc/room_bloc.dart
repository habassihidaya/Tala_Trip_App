import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:tala_trip_app/core/errors/failures.dart';
import '../../domain/usecases/room_usecases.dart';
import 'room_event.dart';
import 'room_state.dart';

class RoomBloc extends Bloc<RoomEvent, RoomState> {
  final String hotelId;
  final GetRooms _getRooms;
  final SaveRoom _saveRoom;
  final DeleteRoom _deleteRoom;

  RoomBloc(this.hotelId, this._getRooms, this._saveRoom, this._deleteRoom)
    : super(const RoomState(loading: true)) {
    on<RoomEvent>(
      _onEvent,
      transformer: (events, mapper) => events.asyncExpand(mapper),
    );
  }

  Future<void> _load(Emitter<RoomState> emit) async {
    emit(const RoomState(loading: true));
    final result = await _getRooms(hotelId);
    result.fold(
      (failure) => emit(RoomState(error: failure.message)),
      (catalog) => emit(RoomState(catalog: catalog)),
    );
  }

  Future<void> _onEvent(RoomEvent event, Emitter<RoomState> emit) async {
    if (event is LoadRooms) {
      await _load(emit);
      return;
    }
    final catalog = state.catalog;
    if (catalog == null) return;
    emit(RoomState(catalog: catalog, saving: true));
    final Either<Failure, Unit> result;
    if (event is SaveRoomRequested) {
      result = await _saveRoom(hotelId, event.room, original: event.original);
    } else if (event is DeleteRoomRequested) {
      result = await _deleteRoom(hotelId, event.original);
    } else {
      return;
    }
    var succeeded = false;
    result.fold<void>(
      (failure) => emit(RoomState(catalog: catalog, error: failure.message)),
      (_) {
        succeeded = true;
        emit(RoomState(catalog: catalog, actionSucceeded: true));
      },
    );
    if (succeeded) await _load(emit);
  }
}
