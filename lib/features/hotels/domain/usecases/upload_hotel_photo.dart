import 'package:fpdart/fpdart.dart';

import 'package:tala_trip_app/core/errors/failures.dart';
import 'package:tala_trip_app/features/hotels/domain/repositories/hotel_photo_repository.dart';

class UploadHotelPhoto {
  final HotelPhotoRepository _repository;

  UploadHotelPhoto(this._repository);

  Future<Either<Failure, String>> call(String filePath) {
    return _repository.uploadPhoto(filePath);
  }
}