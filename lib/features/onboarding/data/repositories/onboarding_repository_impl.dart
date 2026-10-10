import 'package:fpdart/fpdart.dart';
import 'package:tala_trip_app/core/errors/failure_mapper.dart';
import 'package:tala_trip_app/core/errors/failures.dart';
import 'package:tala_trip_app/features/onboarding/data/data_sources/onboarding_local_data_source.dart';
import 'package:tala_trip_app/features/onboarding/domain/repositories/onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  final OnboardingLocalDataSource _dataSource;

  OnboardingRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, bool>> isCompleted() async {
    try {
      final completed = await _dataSource.isCompleted();
      return Right(completed);
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, void>> markCompleted() async {
    try {
      await _dataSource.markCompleted();
      return const Right(null);
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }
}
