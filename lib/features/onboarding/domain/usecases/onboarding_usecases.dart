import 'package:fpdart/fpdart.dart';
import 'package:tala_trip_app/core/errors/failures.dart';
import 'package:tala_trip_app/features/onboarding/domain/repositories/onboarding_repository.dart';

class CheckOnboardingCompleted {
  final OnboardingRepository _repository;

  CheckOnboardingCompleted(this._repository);

  Future<Either<Failure, bool>> call() {
    return _repository.isCompleted();
  }
}

class CompleteOnboarding {
  final OnboardingRepository _repository;

  CompleteOnboarding(this._repository);

  Future<Either<Failure, void>> call() {
    return _repository.markCompleted();
  }
}
