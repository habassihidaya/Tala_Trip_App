import '../models/owner_application_model.dart';

abstract class OwnerApplicationDataSource {
  Future<void> submitApplication(
    OwnerApplicationModel application,
  );

  Future<OwnerApplicationModel?> getMyApplication();
}