import '../../domain/entities/room_entity.dart';

sealed class RoomEvent {}

class LoadRooms extends RoomEvent {}

class SaveRoomRequested extends RoomEvent {
  final RoomEntity room;
  final RoomEntity? original;
  final List<String> photoPaths;

  SaveRoomRequested(
    this.room, {
    this.original,
    List<String> photoPaths = const [],
  }) : photoPaths = List<String>.unmodifiable(photoPaths);
}

class DeleteRoomRequested extends RoomEvent {
  final RoomEntity original;

  DeleteRoomRequested(this.original);
}
