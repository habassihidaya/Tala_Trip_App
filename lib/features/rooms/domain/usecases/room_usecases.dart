import 'package:fpdart/fpdart.dart';
import 'package:tala_trip_app/core/errors/failures.dart';
import '../entities/room_catalog.dart';
import '../entities/room_entity.dart';
import '../repositories/room_repository.dart';

class GetRooms {
  final RoomRepository _repository;
  GetRooms(this._repository);
  Future<Either<Failure, RoomCatalog>> call(String hotelId) =>
      _repository.getRooms(hotelId);
}

class SaveRoom {
  final RoomRepository _repository;
  SaveRoom(this._repository);
  Future<Either<Failure, Unit>> call(
    String hotelId,
    RoomEntity room, {
    RoomEntity? original,
  }) {
    final message = room.validate();
    if (message != null) return Future.value(Left(ServerFailure(message)));
    return _repository.saveRoom(hotelId, room, original: original);
  }
}

class DeleteRoom {
  final RoomRepository _repository;
  DeleteRoom(this._repository);
  Future<Either<Failure, Unit>> call(String hotelId, RoomEntity original) =>
      _repository.deleteRoom(hotelId, original);
}
