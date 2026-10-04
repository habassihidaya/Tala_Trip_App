import '../../domain/entities/room_entity.dart';

sealed class RoomEvent {}

class LoadRooms extends RoomEvent {}

class SaveRoomRequested extends RoomEvent {
  final RoomEntity room;
  final RoomEntity? original;
  SaveRoomRequested(this.room, {this.original});
}

class DeleteRoomRequested extends RoomEvent {
  final RoomEntity original;
  DeleteRoomRequested(this.original);
}
