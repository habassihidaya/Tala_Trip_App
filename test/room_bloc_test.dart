import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:tala_trip_app/core/errors/failures.dart';
import 'package:tala_trip_app/features/hotels/domain/entities/hotel_status.dart';
import 'package:tala_trip_app/features/rooms/domain/entities/room_catalog.dart';
import 'package:tala_trip_app/features/rooms/domain/entities/room_entity.dart';
import 'package:tala_trip_app/features/rooms/domain/repositories/room_repository.dart';
import 'package:tala_trip_app/features/rooms/domain/usecases/room_usecases.dart';
import 'package:tala_trip_app/features/rooms/presentation/bloc/room_bloc.dart';
import 'package:tala_trip_app/features/rooms/presentation/bloc/room_event.dart';

class _Repository implements RoomRepository {
  final rooms = <RoomEntity>[];
  bool failSave = false;
  @override
  Future<Either<Failure, RoomCatalog>> getRooms(String hotelId) async => Right(
    RoomCatalog(
      hotelId: hotelId,
      hotelName: 'Hotel',
      ownerId: 'owner',
      hotelStatus: HotelStatus.draft,
      rooms: rooms,
    ),
  );
  @override
  Future<Either<Failure, Unit>> saveRoom(
    String hotelId,
    RoomEntity room, {
    RoomEntity? original,
  }) async {
    if (failSave) return const Left(ServerFailure('Permission denied'));
    rooms.add(room);
    return Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> deleteRoom(
    String hotelId,
    RoomEntity original,
  ) async {
    rooms.remove(original);
    return Right(unit);
  }
}

void main() {
  const room = RoomEntity(
    type: RoomType.single,
    capacity: 1,
    priceInCentimes: 10000,
    totalRooms: 1,
  );
  test(
    'failed save preserves catalog and successful retry reloads it',
    () async {
      final repository = _Repository();
      final bloc = RoomBloc(
        'hotel',
        GetRooms(repository),
        SaveRoom(repository),
        DeleteRoom(repository),
      );
      final loaded = bloc.stream.firstWhere((state) => state.catalog != null);
      bloc.add(LoadRooms());
      await loaded;
      repository.failSave = true;
      final failed = bloc.stream.firstWhere((state) => state.error != null);
      bloc.add(SaveRoomRequested(room));
      final failure = await failed;
      expect(failure.saving, isFalse);
      expect(failure.catalog, isNotNull);
      expect(failure.catalog!.rooms, isEmpty);
      repository.failSave = false;
      final refreshed = bloc.stream.firstWhere(
        (state) => state.catalog?.rooms.length == 1,
      );
      bloc.add(SaveRoomRequested(room));
      await refreshed;
      expect(bloc.state.catalog!.rooms.single, room);
      await bloc.close();
    },
  );
}
