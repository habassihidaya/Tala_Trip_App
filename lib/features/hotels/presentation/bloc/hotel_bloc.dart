import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tala_trip_app/features/hotels/domain/usecases/hotel_usecases.dart';
import 'package:tala_trip_app/features/hotels/presentation/bloc/hotel_event.dart';
import 'package:tala_trip_app/features/hotels/presentation/bloc/hotel_state.dart';
class HotelBloc extends Bloc<HotelEvent, HotelState> {
  HotelBloc({
    required CreateHotelDraft createHotelDraft,
    required GetMyHotels getMyHotels,
    required GetHotelById getHotelById,
    required AddHotelDraft addHotelDraft,
    required UpdateHotelDraft updateHotelDraft,
    required DeleteHotelDraft deleteHotelDraft,
    required SubmitHotelForReview submitHotelForReview,
    required GetPendingHotels getPendingHotels,
    required ApproveHotel approveHotel,
    required RejectHotel rejectHotel,
    required GetApprovedHotels getApprovedHotels, required getHotels,
  })  : _createHotelDraft = createHotelDraft,
      
        super(InitialState()) {
          on<HotelEvent>(
          _onEventHandler, 
          transformer: (events, mapper) => events.asyncExpand(mapper),
          );
  }

  final CreateHotelDraft _createHotelDraft;
  

  Future<void> _onEventHandler(
    HotelEvent event,
    Emitter<HotelState> emit,
  ) async {
    if (event is CreateHotelDraftEvent) {
      emit(HotelLoadingState());
      final result = await _createHotelDraft(
        ownerId: event.ownerId,
        name: event.name,
        description: event.description,
        wilaya: event.wilaya,
        adress: event.adress,
        phoneNumber: event.phoneNumber,
        images: event.images,
        mapUrl: event.mapUrl,
      );
      result.fold(
        (failure) => emit(HotelErrorState(message: failure.message)),
        (hotel) => emit(InitialState()),
      );
    } 
  }
}