import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../hotels/domain/entities/hotel_entity.dart';
import '../repositories/favorites_repository.dart';

class GetFavoriteIds {
  final FavoritesRepository _repository;

  const GetFavoriteIds(this._repository);

  Future<Either<Failure, Set<String>>> call() {
    return _repository.getFavoriteIds();
  }
}

class GetFavoriteHotels {
  final FavoritesRepository _repository;

  const GetFavoriteHotels(this._repository);

  Future<Either<Failure, List<HotelEntity>>> call() {
    return _repository.getFavoriteHotels();
  }
}

class AddFavorite {
  final FavoritesRepository _repository;

  const AddFavorite(this._repository);

  Future<Either<Failure, Unit>> call({required String hotelId}) {
    return _repository.addFavorite(hotelId: hotelId);
  }
}

class RemoveFavorite {
  final FavoritesRepository _repository;

  const RemoveFavorite(this._repository);

  Future<Either<Failure, Unit>> call({required String hotelId}) {
    return _repository.removeFavorite(hotelId: hotelId);
  }
}
