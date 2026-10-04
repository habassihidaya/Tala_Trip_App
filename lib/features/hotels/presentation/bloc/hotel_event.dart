import 'package:tala_trip_app/features/hotels/domain/entities/hotel_entity.dart';

abstract class HotelEvent {}

class CreateHotelDraftEvent extends HotelEvent {
  final String name;
  final String description;
  final String wilaya;
  final String address;
  final String phoneNumber;
  final List<String> images;
  final String? mapUrl;

  CreateHotelDraftEvent({
    required this.name,
    required this.description,
    required this.wilaya,
    required this.address,
    required this.phoneNumber,
    required this.images,
    this.mapUrl,
  });
}

class GetMyHotelsEvent extends HotelEvent {}

class GetHotelByIdEvent extends HotelEvent {
  final String id;

  GetHotelByIdEvent({required this.id});
}

class UpdateHotelDraftEvent extends HotelEvent {
  final HotelEntity hotel;

  UpdateHotelDraftEvent({required this.hotel});
}

class DeleteHotelDraftEvent extends HotelEvent {
  final String id;

  DeleteHotelDraftEvent({required this.id});
}

class SubmitHotelForReviewEvent extends HotelEvent {
  final String id;

  SubmitHotelForReviewEvent({required this.id});
}

class GetPendingHotelsEvent extends HotelEvent {}

class ApproveHotelEvent extends HotelEvent {
  final String id;

  ApproveHotelEvent({required this.id});
}

class RejectHotelEvent extends HotelEvent {
  final String id;
  final String reason;

  RejectHotelEvent({
    required this.id,
    required this.reason,
  });
}

class GetApprovedHotelsEvent extends HotelEvent {}
