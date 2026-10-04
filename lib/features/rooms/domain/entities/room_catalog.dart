import 'package:tala_trip_app/features/hotels/domain/entities/hotel_status.dart';
import 'room_entity.dart';

class RoomCatalog {
  final String hotelId;
  final String hotelName;
  final String ownerId;
  final HotelStatus hotelStatus;
  final List<RoomEntity> rooms;

  RoomCatalog({
    required this.hotelId,
    required this.hotelName,
    required this.ownerId,
    required this.hotelStatus,
    required List<RoomEntity> rooms,
  }) : rooms = List.unmodifiable(rooms);
}
