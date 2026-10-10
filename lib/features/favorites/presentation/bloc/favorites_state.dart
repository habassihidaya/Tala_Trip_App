import '../../../hotels/domain/entities/hotel_entity.dart';

enum FavoritesStatus { initial, loading, success, failure }

class FavoritesState {
  final Set<String> favoriteIds;
  final List<HotelEntity> hotels;

  final FavoritesStatus idsStatus;
  final FavoritesStatus hotelsStatus;

  final Set<String> updatingHotelIds;

  final String? idsError;
  final String? hotelsError;
  final String? actionError;

  FavoritesState({
    Set<String> favoriteIds = const <String>{},
    List<HotelEntity> hotels = const <HotelEntity>[],
    this.idsStatus = FavoritesStatus.initial,
    this.hotelsStatus = FavoritesStatus.initial,
    Set<String> updatingHotelIds = const <String>{},
    this.idsError,
    this.hotelsError,
    this.actionError,
  }) : favoriteIds = Set<String>.unmodifiable(favoriteIds),
       hotels = List<HotelEntity>.unmodifiable(hotels),
       updatingHotelIds = Set<String>.unmodifiable(updatingHotelIds);

  bool isFavorite(String hotelId) {
    return favoriteIds.contains(hotelId);
  }

  bool isUpdating(String hotelId) {
    return updatingHotelIds.contains(hotelId);
  }

  bool get isEmpty {
    return hotelsStatus == FavoritesStatus.success && hotels.isEmpty;
  }

  FavoritesState copyWith({
    Set<String>? favoriteIds,
    List<HotelEntity>? hotels,
    FavoritesStatus? idsStatus,
    FavoritesStatus? hotelsStatus,
    Set<String>? updatingHotelIds,
    String? idsError,
    String? hotelsError,
    String? actionError,
    bool clearIdsError = false,
    bool clearHotelsError = false,
    bool clearActionError = false,
  }) {
    return FavoritesState(
      favoriteIds: favoriteIds ?? this.favoriteIds,
      hotels: hotels ?? this.hotels,
      idsStatus: idsStatus ?? this.idsStatus,
      hotelsStatus: hotelsStatus ?? this.hotelsStatus,
      updatingHotelIds: updatingHotelIds ?? this.updatingHotelIds,
      idsError: clearIdsError ? null : idsError ?? this.idsError,
      hotelsError: clearHotelsError ? null : hotelsError ?? this.hotelsError,
      actionError: clearActionError ? null : actionError ?? this.actionError,
    );
  }
}
