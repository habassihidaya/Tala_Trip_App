import 'package:tala_trip_app/features/rooms/domain/entities/room_entity.dart';

class RoomModel {
  final RoomEntity _room;

  const RoomModel.fromEntity(this._room);

  factory RoomModel.fromJson(String type, Map<String, dynamic> data) {
    final rawImages = data['images'];

    if (rawImages != null &&
        (rawImages is! List || rawImages.any((image) => image is! String))) {
      throw const FormatException('Invalid stored room photos.');
    }

    final room = RoomEntity(
      type: RoomType.values.byName(type),
      capacity: data['capacity'] as int,
      priceInCentimes: data['priceInCentimes'] as int,
      totalRooms: data['totalRooms'] as int,
      images: rawImages == null
          ? const []
          : List<String>.unmodifiable(rawImages as List),
    );

    if (room.validate() != null) {
      throw const FormatException('Invalid stored room inventory.');
    }

    return RoomModel.fromEntity(room);
  }

  RoomEntity toEntity() => _room;

  Map<String, dynamic> toJson() => {
    'capacity': _room.capacity,
    'priceInCentimes': _room.priceInCentimes,
    'totalRooms': _room.totalRooms,
    'images': _room.images,
  };
}
