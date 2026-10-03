import 'package:fpdart/fpdart.dart';
import 'package:tala_trip_app/core/errors/failures.dart';
import 'package:tala_trip_app/features/hotels/domain/entities/hotel_entity.dart';
import 'package:tala_trip_app/features/hotels/domain/repositories/hotel_repository.dart';

class CreateHotelDraft {
  CreateHotelDraft(this._repository);
  final HotelRepository _repository;
  Future<Either<Failure, List<HotelEntity>>> call({
    required String ownerId,
    required String name,
    required String description,
    required String wilaya,
    required String adress,
    required double phoneNumber,
    required List<String> images,
    required String mapUrl,
  }) {
    return _repository.createHotelDraft(
      ownerId: ownerId,
      name: name,
      description: description,
      wilaya: wilaya,
      adress: adress,
      phoneNumber: phoneNumber,
      images: images,
      mapUrl: mapUrl,
    );
  }

}
class GetMyHotels {
  GetMyHotels(this._repository);
  final HotelRepository _repository;
  Future<Either<Failure, List<HotelEntity>>> call() {
    return _repository.getMyHotels();
  }
}

class GetHotelById {
  GetHotelById(this._repository);
  final HotelRepository _repository;
  Future<Either<Failure, HotelEntity>> call(String id) {
    return _repository.getHotelById(id);
  }
}

class AddHotelDraft {
  AddHotelDraft(this._repository);
  final HotelRepository _repository;
  Future<Either<Failure, Unit>> call(HotelEntity hotel) {
    return _repository.addHotelDraft(hotel);
  }
}
class UpdateHotelDraft {
  UpdateHotelDraft(this._repository);
  final HotelRepository _repository;
  Future<Either<Failure, Unit>> call(HotelEntity hotel) {
    return _repository.updateHotelDraft(hotel);
  }
}

class DeleteHotelDraft {
  DeleteHotelDraft(this._repository);
  final HotelRepository _repository;
  Future<Either<Failure, Unit>> call(String id) {
    return _repository.deleteHotelDraft(id);
  }
}
class SubmitHotelForReview {
  SubmitHotelForReview(this._repository);
  final HotelRepository _repository;
  Future<Either<Failure, List<HotelEntity>>> call() {
    return _repository.submitHotelForReview();
  }
}
class GetPendingHotels {
  GetPendingHotels(this._repository);
  final HotelRepository _repository;
  Future<Either<Failure, List<HotelEntity>>> call() {
    return _repository.getPendingHotels();
  }
}
class ApproveHotel {
  ApproveHotel(this._repository);
  final HotelRepository _repository;
  Future<Either<Failure, Unit>> call(String id) {
    return _repository.approveHotel(id);
  }
}
class RejectHotel {
  RejectHotel(this._repository);
  final HotelRepository _repository;
  Future<Either<Failure, Unit>> call(String id, String reason) {
    return _repository.rejectHotel(id, reason);
  }
}
class GetApprovedHotels {
  GetApprovedHotels(this._repository);
  final HotelRepository _repository;
  Future<Either<Failure, List<HotelEntity>>> call() {
    return _repository.getApprovedHotels();
  }
}
