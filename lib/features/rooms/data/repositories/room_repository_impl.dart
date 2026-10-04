import 'package:fpdart/fpdart.dart';
import 'package:tala_trip_app/core/errors/failure_mapper.dart';
import 'package:tala_trip_app/core/errors/failures.dart';
import 'package:tala_trip_app/features/hotels/domain/entities/hotel_status.dart';
import '../../domain/entities/room_catalog.dart';
import '../../domain/entities/room_entity.dart';
import '../../domain/repositories/room_repository.dart';
import '../data_sources/room_data_source.dart';
import '../models/room_model.dart';

class RoomRepositoryImpl implements RoomRepository {
  final RoomDataSource _dataSource;
  RoomRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, RoomCatalog>> getRooms(String hotelId) async {
    try {
      final data = await _dataSource.getHotel(hotelId);
      final rooms = Map<String, dynamic>.from(data['rooms'] as Map? ?? {});
      return Right(
        RoomCatalog(
          hotelId: hotelId,
          hotelName: data['name'] as String,
          ownerId: data['ownerId'] as String,
          hotelStatus: HotelStatus.values.byName(data['status'] as String),
          rooms: [
            for (final type in RoomType.values)
              if (rooms.containsKey(type.name))
                RoomModel.fromJson(
                  type.name,
                  Map<String, dynamic>.from(rooms[type.name] as Map),
                ).toEntity(),
          ],
        ),
      );
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveRoom(
    String hotelId,
    RoomEntity room, {
    RoomEntity? original,
  }) async {
    try {
      await _dataSource.saveRoom(
        hotelId,
        RoomModel.fromEntity(room),
        original: original == null ? null : RoomModel.fromEntity(original),
      );
      return Right(unit);
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteRoom(
    String hotelId,
    RoomEntity original,
  ) async {
    try {
      await _dataSource.deleteRoom(hotelId, RoomModel.fromEntity(original));
      return Right(unit);
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }
}
