import 'package:tala_trip_app/features/hotels/domain/entities/hotel_entity.dart';

abstract class HotelState {}

class HotelInitialState extends HotelState {}

class HotelLoadingState extends HotelState {}

class HotelsLoadedState extends HotelState {
  final List<HotelEntity> hotels;

  HotelsLoadedState({required this.hotels});
}

class HotelsEmptyState extends HotelState {}

class HotelDetailsLoadedState extends HotelState {
  final HotelEntity hotel;

  HotelDetailsLoadedState({required this.hotel});
}

class HotelDraftCreatedState extends HotelState {
  final HotelEntity hotel;

  HotelDraftCreatedState({required this.hotel});
}

enum HotelAction {
  updated,
  deleted,
  submitted,
  approved,
  rejected,
}

class HotelActionSuccessState extends HotelState {
  final String hotelId;
  final HotelAction action;

  HotelActionSuccessState({
    required this.hotelId,
    required this.action,
  });
}

class HotelErrorState extends HotelState {
  final String message;

  HotelErrorState({required this.message});
}


