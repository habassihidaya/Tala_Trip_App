import '../../../hotels/domain/entities/hotel_entity.dart';

abstract class FavoritesEvent {
  const FavoritesEvent();
}

/// Load saved IDs so hotel cards can show the correct heart icon.
class FavoritesStarted extends FavoritesEvent {
  const FavoritesStarted();
}

/// Load hotel details when opening or refreshing the Favorites page.
class FavoriteHotelsRequested extends FavoritesEvent {
  const FavoriteHotelsRequested();
}

/// Add or remove a hotel when its heart button is tapped.
class FavoriteToggled extends FavoritesEvent {
  final HotelEntity hotel;

  const FavoriteToggled({required this.hotel});
}
