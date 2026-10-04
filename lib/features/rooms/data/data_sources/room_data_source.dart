import '../models/room_model.dart';

abstract class RoomDataSource {
  Future<Map<String, dynamic>> getHotel(String hotelId);
  Future<void> saveRoom(String hotelId, RoomModel room, {RoomModel? original});
  Future<void> deleteRoom(String hotelId, RoomModel original);
}
