import 'package:fpdart/fpdart.dart';

import 'package:tala_trip_app/core/errors/failures.dart';

abstract class HotelPhotoRepository {
  Future<Either<Failure, String>> uploadPhoto(String filePath);
}