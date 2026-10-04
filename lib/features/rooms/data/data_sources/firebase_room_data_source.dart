import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tala_trip_app/core/errors/exceptions.dart';
import '../models/room_model.dart';
import 'room_data_source.dart';

class FirebaseRoomDataSource implements RoomDataSource {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  FirebaseRoomDataSource(this._auth, this._firestore);

  @override
  Future<Map<String, dynamic>> getHotel(String hotelId) async {
    if (_auth.currentUser == null) throw const UnauthenticatedException();
    final snapshot = await _firestore
        .collection('hotels')
        .doc(hotelId)
        .get(const GetOptions(source: Source.server));
    final data = snapshot.data();
    if (data == null) throw const HotelNotFoundException();
    return {...data, 'id': snapshot.id};
  }

  @override
  Future<void> saveRoom(
    String hotelId,
    RoomModel room, {
    RoomModel? original,
  }) => _write(hotelId, room, original, deleting: false);

  @override
  Future<void> deleteRoom(String hotelId, RoomModel original) =>
      _write(hotelId, original, original, deleting: true);

  Future<void> _write(
    String hotelId,
    RoomModel room,
    RoomModel? original, {
    required bool deleting,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw const UnauthenticatedException();
    final message = room.toEntity().validate();
    if (message != null) throw HotelOperationException(message);
    final type = room.toEntity().type.name;
    if (original != null && original.toEntity().type.name != type) {
      throw const HotelOperationException('A room type cannot be changed.');
    }
    final document = _firestore.collection('hotels').doc(hotelId);
    await _firestore.runTransaction<void>((transaction) async {
      final snapshot = await transaction.get(document);
      final data = snapshot.data();
      if (data == null) throw const HotelNotFoundException();
      if (data['ownerId'] != user.uid) {
        throw const HotelOperationException(
          'You can only manage your own hotel rooms.',
        );
      }
      if (!['draft', 'rejected', 'approved'].contains(data['status'])) {
        throw const HotelOperationException(
          'Rooms cannot change while the hotel is under review.',
        );
      }
      final rooms = Map<String, dynamic>.from(data['rooms'] as Map? ?? {});
      final current = rooms[type];
      if (original == null
          ? current != null
          : current == null ||
                RoomModel.fromJson(
                      type,
                      Map<String, dynamic>.from(current as Map),
                    ).toEntity() !=
                    original.toEntity()) {
        throw const HotelOperationException(
          'This room type changed on another screen. Reload rooms before editing again.',
        );
      }
      if (deleting) {
        rooms.remove(type);
      } else {
        rooms[type] = room.toJson();
      }
      transaction.update(document, {
        'rooms': rooms,
        'updatedAt': FieldValue.serverTimestamp(),
        if (data['status'] == 'rejected') ...{
          'status': 'draft',
          'reviewedAt': null,
          'reviewedBy': null,
          'rejectionReason': null,
        },
      });
    });
  }
}
