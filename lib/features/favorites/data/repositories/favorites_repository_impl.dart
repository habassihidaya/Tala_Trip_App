import 'package:firebase_auth/firebase_auth.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../hotels/domain/entities/hotel_entity.dart';
import '../../../hotels/domain/repositories/hotel_repository.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../data_sources/favorites_data_source.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  final FavoritesDataSource _dataSource;
  final HotelRepository _hotelRepository;
  final FirebaseAuth _auth;

  FavoritesRepositoryImpl(this._dataSource, this._hotelRepository, this._auth);

  @override
  Future<Either<Failure, Set<String>>> getFavoriteIds() {
    return _run((userId) async {
      final ids = await _dataSource.getFavoriteIds(userId: userId);

      return Right(Set<String>.unmodifiable(ids));
    });
  }

  @override
  Future<Either<Failure, List<HotelEntity>>> getFavoriteHotels() {
    return _run((userId) async {
      final ids = await _dataSource.getFavoriteIds(userId: userId);

      if (ids.isEmpty) {
        return const Right(<HotelEntity>[]);
      }

      if (_auth.currentUser?.uid != userId) {
        return const Left(UnauthenticatedFailure());
      }

      final result = await _hotelRepository.getApprovedHotels();

      return result.map(
        (hotels) => hotels
            .where((hotel) => ids.contains(hotel.id))
            .toList(growable: false),
      );
    });
  }

  @override
  Future<Either<Failure, Unit>> addFavorite({required String hotelId}) {
    return _changeFavorite(hotelId: hotelId, shouldAdd: true);
  }

  @override
  Future<Either<Failure, Unit>> removeFavorite({required String hotelId}) {
    return _changeFavorite(hotelId: hotelId, shouldAdd: false);
  }

  Future<Either<Failure, Unit>> _changeFavorite({
    required String hotelId,
    required bool shouldAdd,
  }) {
    return _run((userId) async {
      if (hotelId.trim().isEmpty) {
        return const Left(UnexpectedFailure('Please select a valid hotel.'));
      }

      if (shouldAdd) {
        await _dataSource.addFavorite(userId: userId, hotelId: hotelId);
      } else {
        await _dataSource.removeFavorite(userId: userId, hotelId: hotelId);
      }

      return const Right(unit);
    });
  }

  Future<Either<Failure, T>> _run<T>(
    Future<Either<Failure, T>> Function(String userId) action,
  ) async {
    final userId = _auth.currentUser?.uid;

    if (userId == null) {
      return const Left(UnauthenticatedFailure());
    }

    try {
      final result = await action(userId);

      // Ignore results belonging to an account that has signed out.
      if (_auth.currentUser?.uid != userId) {
        return const Left(UnauthenticatedFailure());
      }

      return result;
    } on StateError {
      return const Left(
        UnexpectedFailure(
          'Could not save your favorites on this device. Please try again.',
        ),
      );
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }
}
