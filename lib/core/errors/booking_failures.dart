import 'failures.dart';

class BookingOperationFailure extends Failure {
  const BookingOperationFailure(super.message);
}

class BookingOutcomeUnknownFailure extends Failure {
  final String operationId;

  const BookingOutcomeUnknownFailure({
    required this.operationId,
    required String message,
  }) : super(message);

  @override
  List<Object?> get props => [message, operationId];
}

class BookingLocalStorageFailure extends Failure {
  const BookingLocalStorageFailure(super.message);
}
