import '../models/booking_submission_model.dart';

abstract class BookingSubmissionLocalDataSource {
  // Persist the submission before any attempt to send it.
  //
  // Saving the same submission again is allowed.
  // Replacing the same request ID with different details is not.
  // Throw if persistence fails.
  Future<void> saveSubmission(BookingSubmissionModel submission);

  // Load unresolved submissions belonging to this account only.
  //
  // Return an empty list when there are none.
  // Throw if saved data cannot be read; do not silently discard it.
  Future<List<BookingSubmissionModel>> getSubmissions(String travelerId);

  // Remove the local record after the remote outcome is known:
  // either a booking exists or the request ID is permanently closed.
  //
  // Removing an already absent record is allowed.
  Future<void> removeSubmission({
    required String travelerId,
    required String requestId,
  });
}
