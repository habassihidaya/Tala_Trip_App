abstract class FavoritesDataSource {
  Future<Set<String>> getFavoriteIds({required String userId});

  Future<void> addFavorite({required String userId, required String hotelId});

  Future<void> removeFavorite({
    required String userId,
    required String hotelId,
  });
}
