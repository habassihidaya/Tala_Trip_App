import 'package:tala_trip_app/features/hotels/domain/entities/hotel_entity.dart';

abstract class HotelEvent {}

class CreateHotelDraftEvent extends HotelEvent {
  final String name;
  final String description;
  final String wilaya;
  final String address;
  final String phoneNumber;
  final List<String> photoPaths;
  final String? mapUrl;

  CreateHotelDraftEvent({
    required this.name,
    required this.description,
    required this.wilaya,
    required this.address,
    required this.phoneNumber,
    required List<String> photoPaths,
    this.mapUrl,
  }) : photoPaths = List.unmodifiable(photoPaths);
}

class GetMyHotelsEvent extends HotelEvent {}

class GetHotelByIdEvent extends HotelEvent {
  final String id;

  GetHotelByIdEvent({required this.id});
}

class UpdateHotelDraftEvent extends HotelEvent {
  final HotelEntity hotel;
  final List<String> photoPaths;

  UpdateHotelDraftEvent({
    required this.hotel,
    List<String> photoPaths = const [],
  }) : photoPaths = List.unmodifiable(photoPaths);
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
