import 'package:fpdart/fpdart.dart';

import 'package:tala_trip_app/core/errors/failure_mapper.dart';
import 'package:tala_trip_app/core/errors/failures.dart';
import 'package:tala_trip_app/features/hotels/data/data_sources/hotel_data_sources.dart';
import 'package:tala_trip_app/features/hotels/data/models/hotel_model.dart';
import 'package:tala_trip_app/features/hotels/domain/entities/hotel_entity.dart';
import 'package:tala_trip_app/features/hotels/domain/repositories/hotel_repository.dart';

class HotelRepositoryImpl implements HotelRepository {
  final HotelDataSource _dataSource;

  HotelRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, HotelEntity>> createHotelDraft({
    required String name,
    required String description,
    required String wilaya,
    required String address,
    required String phoneNumber,
    required List<String> images,
    String? mapUrl,
  }) async {
    try {
      final hotel = await _dataSource.createHotelDraft(
        name: name,
        description: description,
        wilaya: wilaya,
        address: address,
        phoneNumber: phoneNumber,
        images: images,
        mapUrl: mapUrl,
      );

      return Right(hotel.toEntity());
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, List<HotelEntity>>> getMyHotels() async {
    try {
      final hotels = await _dataSource.getMyHotels();

      return Right(
        hotels.map((hotel) => hotel.toEntity()).toList(),
      );
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, HotelEntity>> getHotelById(String id) async {
    try {
      final hotel = await _dataSource.getHotelById(id);

      return Right(hotel.toEntity());
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateHotelDraft(
    HotelEntity hotel,
  ) async {
    try {
      await _dataSource.updateHotelDraft(
        HotelModel.fromEntity(hotel),
      );

      return Right(unit);
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteHotelDraft(String id) async {
    try {
      await _dataSource.deleteHotelDraft(id);

      return Right(unit);
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, Unit>> submitHotelForReview(String id) async {
    try {
      await _dataSource.submitHotelForReview(id);

      return Right(unit);
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, List<HotelEntity>>> getPendingHotels() async {
    try {
      final hotels = await _dataSource.getPendingHotels();

      return Right(
        hotels.map((hotel) => hotel.toEntity()).toList(),
      );
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, Unit>> approveHotel(String id) async {
    try {
      await _dataSource.approveHotel(id);

      return Right(unit);
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, Unit>> rejectHotel(
    String id,
    String reason,
  ) async {
    try {
      await _dataSource.rejectHotel(id, reason);

      return Right(unit);
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, List<HotelEntity>>> getApprovedHotels() async {
    try {
      final hotels = await _dataSource.getApprovedHotels();

      return Right(
        hotels.map((hotel) => hotel.toEntity()).toList(),
      );
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }
}