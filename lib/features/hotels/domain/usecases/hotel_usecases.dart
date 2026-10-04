import 'package:fpdart/fpdart.dart';

import 'package:tala_trip_app/core/errors/failures.dart';
import 'package:tala_trip_app/features/hotels/domain/entities/hotel_entity.dart';
import 'package:tala_trip_app/features/hotels/domain/repositories/hotel_repository.dart';

class CreateHotelDraft {
  final HotelRepository _repository;

  CreateHotelDraft(this._repository);

  Future<Either<Failure, HotelEntity>> call({
    required String name,
    required String description,
    required String wilaya,
    required String address,
    required String phoneNumber,
    required List<String> images,
    String? mapUrl,
  }) {
    return _repository.createHotelDraft(
      name: name,
      description: description,
      wilaya: wilaya,
      address: address,
      phoneNumber: phoneNumber,
      images: images,
      mapUrl: mapUrl,
    );
  }
}

class GetMyHotels {
  final HotelRepository _repository;

  GetMyHotels(this._repository);

  Future<Either<Failure, List<HotelEntity>>> call() {
    return _repository.getMyHotels();
  }
}

class GetHotelById {
  final HotelRepository _repository;

  GetHotelById(this._repository);

  Future<Either<Failure, HotelEntity>> call(String id) {
    return _repository.getHotelById(id);
  }
}

class UpdateHotelDraft {
  final HotelRepository _repository;

  UpdateHotelDraft(this._repository);

  Future<Either<Failure, Unit>> call(HotelEntity hotel) {
    return _repository.updateHotelDraft(hotel);
  }
}

class DeleteHotelDraft {
  final HotelRepository _repository;

  DeleteHotelDraft(this._repository);

  Future<Either<Failure, Unit>> call(String id) {
    return _repository.deleteHotelDraft(id);
  }
}

class SubmitHotelForReview {
  final HotelRepository _repository;

  SubmitHotelForReview(this._repository);

  Future<Either<Failure, Unit>> call(String id) {
    return _repository.submitHotelForReview(id);
  }
}

class GetPendingHotels {
  final HotelRepository _repository;

  GetPendingHotels(this._repository);

  Future<Either<Failure, List<HotelEntity>>> call() {
    return _repository.getPendingHotels();
  }
}

class ApproveHotel {
  final HotelRepository _repository;

  ApproveHotel(this._repository);

  Future<Either<Failure, Unit>> call(String id) {
    return _repository.approveHotel(id);
  }
}

class RejectHotel {
  final HotelRepository _repository;

  RejectHotel(this._repository);

  Future<Either<Failure, Unit>> call(
    String id,
    String reason,
  ) {
    return _repository.rejectHotel(id, reason);
  }
}

class GetApprovedHotels {
  final HotelRepository _repository;

  GetApprovedHotels(this._repository);

  Future<Either<Failure, List<HotelEntity>>> call() {
    return _repository.getApprovedHotels();
  }
}
