import 'package:tala_trip_app/features/hotels/data/models/hotel_model.dart';

abstract class HotelDataSource {
  Future<HotelModel> createHotelDraft({
    required String name,
    required String description,
    required String wilaya,
    required String address,
    required String phoneNumber,
    required List<String> images,
    String? mapUrl,
  });

  Future<List<HotelModel>> getMyHotels();

  Future<HotelModel> getHotelById(String id);

  Future<void> updateHotelDraft(HotelModel hotel);

  Future<void> deleteHotelDraft(String id);

  Future<void> submitHotelForReview(String id);

  Future<List<HotelModel>> getPendingHotels();

  Future<void> approveHotel(String id);

  Future<void> rejectHotel(String id, String reason);

  Future<List<HotelModel>> getApprovedHotels();
}
