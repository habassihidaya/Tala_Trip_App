import 'package:fpdart/fpdart.dart';

import 'package:tala_trip_app/core/errors/failures.dart';
import 'package:tala_trip_app/features/hotels/domain/entities/hotel_entity.dart';

abstract class HotelRepository {
  Future<Either<Failure, HotelEntity>> createHotelDraft({
    required String name,
    required String description,
    required String wilaya,
    required String address,
    required String phoneNumber,
    required List<String> images,
    String? mapUrl,
  });

  Future<Either<Failure, List<HotelEntity>>> getMyHotels();

  Future<Either<Failure, HotelEntity>> getHotelById(String id);

  Future<Either<Failure, Unit>> updateHotelDraft(HotelEntity hotel);

  Future<Either<Failure, Unit>> deleteHotelDraft(String id);

  Future<Either<Failure, Unit>> submitHotelForReview(String id);

  Future<Either<Failure, List<HotelEntity>>> getPendingHotels();

  Future<Either<Failure, Unit>> approveHotel(String id);

  Future<Either<Failure, Unit>> rejectHotel(
    String id,
    String reason,
  );

  Future<Either<Failure, List<HotelEntity>>> getApprovedHotels();
}