abstract class HotelState{}
class InitialState extends HotelState{}
class HotelLoadingState extends HotelState{}
class HotelErrorState extends HotelState{
  HotelErrorState({required this.message});
  final String message;
}


