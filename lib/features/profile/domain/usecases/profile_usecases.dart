import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../repositories/profile_repository.dart';

class GetProfile {
  final ProfileRepository _repository;

  const GetProfile(this._repository);

  Future<Either<Failure, UserEntity>> call() {
    return _repository.getProfile();
  }
}

class UpdateProfileName {
  final ProfileRepository _repository;

  const UpdateProfileName(this._repository);

  Future<Either<Failure, UserEntity>> call({required String username}) {
    return _repository.updateName(username: username.trim());
  }
}

class UpdateProfilePhoto {
  final ProfileRepository _repository;

  const UpdateProfilePhoto(this._repository);

  Future<Either<Failure, UserEntity>> call({required String filePath}) {
    return _repository.updatePhoto(filePath: filePath);
  }
}
