import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import 'package:tala_trip_app/core/errors/failures.dart';
import 'package:tala_trip_app/features/hotels/domain/usecases/upload_hotel_photo.dart';

import '../../domain/entities/room_entity.dart';
import '../../domain/usecases/room_usecases.dart';
import 'room_event.dart';
import 'room_state.dart';

class RoomBloc extends Bloc<RoomEvent, RoomState> {
  final String hotelId;
  final GetRooms _getRooms;
  final SaveRoom _saveRoom;
  final DeleteRoom _deleteRoom;
  final UploadHotelPhoto _uploadPhoto;

  // Reuse successful uploads if saving fails and the owner retries.
  final Map<String, String> _uploadedPhotos = {};

  RoomBloc(
    this.hotelId,
    this._getRooms,
    this._saveRoom,
    this._deleteRoom,
    this._uploadPhoto,
  ) : super(const RoomState(loading: true)) {
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

  Future<Either<Failure, String>> _uploadOnce(String path) async {
    final cachedUrl = _uploadedPhotos[path];

    if (cachedUrl != null) {
      return Right(cachedUrl);
    }

    final result = await _uploadPhoto(path);

    result.fold<void>((_) {}, (url) {
      _uploadedPhotos[path] = url;
    });

    return result;
  }

  Future<Either<Failure, Unit>> _saveWithPhotos(SaveRoomRequested event) async {
    final validationMessage = event.room.validate();

    if (validationMessage != null) {
      return Left(ServerFailure(validationMessage));
    }

    if (event.room.images.length + event.photoPaths.length > 10) {
      return Left(ServerFailure('You can add up to 10 photos per room type.'));
    }

    final images = List<String>.of(event.room.images);

    for (final path in event.photoPaths) {
      final result = await _uploadOnce(path);
      Failure? uploadFailure;

      result.fold<void>(
        (failure) {
          uploadFailure = failure;
        },
        (url) {
          images.add(url);
        },
      );

      final failure = uploadFailure;

      if (failure != null) {
        return Left(failure);
      }
    }

    final roomWithPhotos = RoomEntity(
      type: event.room.type,
      capacity: event.room.capacity,
      priceInCentimes: event.room.priceInCentimes,
      totalRooms: event.room.totalRooms,
      images: List<String>.unmodifiable(images),
    );

    return _saveRoom(hotelId, roomWithPhotos, original: event.original);
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
      result = await _saveWithPhotos(event);
    } else if (event is DeleteRoomRequested) {
      result = await _deleteRoom(hotelId, event.original);
    } else {
      return;
    }

    var succeeded = false;

    result.fold<void>(
      (failure) {
        emit(RoomState(catalog: catalog, error: failure.message));
      },
      (_) {
        succeeded = true;
        emit(RoomState(catalog: catalog, actionSucceeded: true));
      },
    );

    if (succeeded) {
      _uploadedPhotos.clear();
      await _load(emit);
    }
  }
}
