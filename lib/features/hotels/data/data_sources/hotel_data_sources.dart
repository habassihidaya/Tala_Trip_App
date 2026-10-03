import 'package:tala_trip_app/features/hotels/data/models/hotel_model.dart';

abstract class HotelDataSource {
  Future<List<HotelModel>> createHotelDraft({
    required String ownerId,
    required String name,
    required String description,
    required String wilaya,
    required String adress,
    required double phoneNumber,
    required List<String> images,
    required String mapUrl,
  });
  Future<List<HotelModel>> getMyHotels();
  Future<HotelModel> getHotelById(String id);
  Future<void> addHotelDraft(HotelModel hotel);
  Future<void> updateHotelDraft(HotelModel hotel);
  Future<void> deleteHotelDraft(String id);
  Future<List<HotelModel>> submitHotelForReview();
  Future<List<HotelModel>> getPendingHotels();
  Future<void> approveHotel(String id);
  Future<void> rejectHotel(String id, String reason);
  Future<List<HotelModel>> getApprovedHotels();
  
  
}