import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/user_entity.dart';

abstract class ProfileRepository {
  /// Loads the currently signed-in user's profile.
  Future<Either<Failure, UserEntity>> getProfile();

  /// Updates the currently signed-in user's display name.
  Future<Either<Failure, UserEntity>> updateName({required String username});

  /// Uploads a selected photo and saves its URL in the user's profile.
  Future<Either<Failure, UserEntity>> updatePhoto({required String filePath});
}
