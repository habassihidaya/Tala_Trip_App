// The operation could not proceed for a known reason.
// Example: the room is no longer available.
class BookingOperationException implements Exception {
  final String message;

  const BookingOperationException(this.message);
}

// The operation may have reached Firebase,
// but we could not confirm its outcome.
class BookingOutcomeUnknownException implements Exception {
  final String operationId;
  final String message;

  const BookingOutcomeUnknownException({
    required this.operationId,
    required this.message,
  });
}

// The local recovery record could not be saved,
// read, or removed.
class BookingLocalStorageException implements Exception {
  final String message;

  const BookingLocalStorageException(this.message);
}