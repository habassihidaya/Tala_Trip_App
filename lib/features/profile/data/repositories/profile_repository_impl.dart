import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../data_sources/profile_data_source.dart';
import '../data_sources/profile_photo_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileDataSource _dataSource;
  final ProfilePhotoDataSource _photoDataSource;

  ProfileRepositoryImpl({
    required this._dataSource,
    required this._photoDataSource,
  });

  @override
  Future<Either<Failure, UserEntity>> getProfile() {
    return _run(() => _dataSource.getProfile());
  }

  @override
  Future<Either<Failure, UserEntity>> updateName({required String username}) {
    final name = username.trim();

    if (name.isEmpty) {
      return Future.value(
        const Left<Failure, UserEntity>(ServerFailure('Enter your name.')),
      );
    }

    if (name.length > 120) {
      return Future.value(
        const Left<Failure, UserEntity>(
          ServerFailure('Use no more than 120 characters.'),
        ),
      );
    }

    return _run(() => _dataSource.updateName(username: name));
  }

  @override
  Future<Either<Failure, UserEntity>> updatePhoto({required String filePath}) {
    if (filePath.trim().isEmpty) {
      return Future.value(
        const Left<Failure, UserEntity>(
          ServerFailure('Choose a photo from your gallery.'),
        ),
      );
    }

    return _run(() async {
      // Remember which account started the upload.
      final profile = await _dataSource.getProfile();

      final photoUrl = await _photoDataSource.uploadPhoto(filePath: filePath);

      return _dataSource.updatePhotoUrl(
        photoUrl: photoUrl,
        expectedUserId: profile.id,
      );
    });
  }

  Future<Either<Failure, UserEntity>> _run(
    Future<UserModel> Function() action,
  ) async {
    try {
      final model = await action();
      return Right(model.toEntity());
    } on ProfileOperationException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }
}
