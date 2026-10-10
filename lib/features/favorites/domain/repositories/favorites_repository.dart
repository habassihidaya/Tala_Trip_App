import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../hotels/domain/entities/hotel_entity.dart';

abstract class FavoritesRepository {
  Future<Either<Failure, Set<String>>> getFavoriteIds();

  Future<Either<Failure, List<HotelEntity>>> getFavoriteHotels();

  Future<Either<Failure, Unit>> addFavorite({required String hotelId});

  Future<Either<Failure, Unit>> removeFavorite({required String hotelId});
}
