import 'package:fpdart/fpdart.dart';
import 'package:tala_trip_app/core/errors/failures.dart';
import '../entities/room_catalog.dart';
import '../entities/room_entity.dart';

abstract class RoomRepository {
  Future<Either<Failure, RoomCatalog>> getRooms(String hotelId);
  Future<Either<Failure, Unit>> saveRoom(
    String hotelId,
    RoomEntity room, {
    RoomEntity? original,
  });
  Future<Either<Failure, Unit>> deleteRoom(String hotelId, RoomEntity original);
}
