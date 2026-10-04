import 'package:fpdart/fpdart.dart';
import 'package:flutter/foundation.dart';

import 'package:tala_trip_app/core/errors/failure_mapper.dart';
import 'package:tala_trip_app/core/errors/failures.dart';
import 'package:tala_trip_app/features/hotels/data/data_sources/hotel_photo_data_source.dart';
import 'package:tala_trip_app/features/hotels/domain/repositories/hotel_photo_repository.dart';

class HotelPhotoRepositoryImpl implements HotelPhotoRepository {
  final HotelPhotoDataSource _dataSource;

  HotelPhotoRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, String>> uploadPhoto(
    String filePath,
  ) async {
    try {
      final url = await _dataSource.uploadPhoto(filePath);

      return Right(url);
    } catch (error, stackTrace) {
  debugPrint('Hotel photo upload failed: $error');
  debugPrintStack(stackTrace: stackTrace);

  return Left(mapExceptionToFailure(error));
}
  }
}