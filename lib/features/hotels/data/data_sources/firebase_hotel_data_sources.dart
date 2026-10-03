import 'package:tala_trip_app/features/hotels/data/data_sources/hotel_data_sources.dart';
import 'package:tala_trip_app/features/hotels/data/models/hotel_model.dart';

class FirebaseHotelDataSource implements HotelDataSource {
  @override
  Future<List<HotelModel>> createHotelDraft({
    required String ownerId,
    required String name,
    required String description,
    required String wilaya,
    required String adress,
    required double phoneNumber,
    required List<String> images,
    required String mapUrl,
  }) {
    // Implementation for creating hotel draft in Firebase
    throw UnimplementedError();
  }

  @override
  Future<List<HotelModel>> getMyHotels() {
    // Implementation for fetching my hotels from Firebase
    throw UnimplementedError();
  }

  @override
  Future<HotelModel> getHotelById(String id) {
    // Implementation for fetching hotel by ID from Firebase
    throw UnimplementedError();
  }

  @override
  Future<void> addHotelDraft(HotelModel hotel) {
    // Implementation for adding hotel draft to Firebase
    throw UnimplementedError();
  }

  @override
  Future<void> updateHotelDraft(HotelModel hotel) {
    // Implementation for updating hotel draft in Firebase
    throw UnimplementedError();
  }

  @override
  Future<void> deleteHotelDraft(String id) {
    // Implementation for deleting hotel draft from Firebase
    throw UnimplementedError();
  }

  @override
  Future<List<HotelModel>> submitHotelForReview() {
    // Implementation for submitting hotel for review in Firebase
    throw UnimplementedError();
  }

  @override
  Future<List<HotelModel>> getPendingHotels() {
    // Implementation for fetching pending hotels from Firebase
    throw UnimplementedError();
  }

  @override
  Future<void> approveHotel(String id) {
    // Implementation for approving hotel in Firebase
    throw UnimplementedError();
  }

  @override
  Future<void> rejectHotel(String id, String reason) {
    // Implementation for rejecting hotel in Firebase
    throw UnimplementedError();
  }

  @override
  Future<List<HotelModel>> getApprovedHotels() {
    // Implementation for fetching approved hotels from Firebase
    throw UnimplementedError();
  }
}