
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/owner_application_entity.dart';

abstract class OwnerApplicationRepository {
  Future<Either<Failure, void>> submitApplication(
    OwnerApplicationEntity application,
  );

  Future<Either<Failure, OwnerApplicationEntity?>> getMyApplication();
}