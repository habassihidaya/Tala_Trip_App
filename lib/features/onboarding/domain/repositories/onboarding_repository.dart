import 'package:fpdart/fpdart.dart';
import 'package:tala_trip_app/core/errors/failures.dart';

abstract class OnboardingRepository {
  Future<Either<Failure, bool>> isCompleted();

  Future<Either<Failure, void>> markCompleted();
}