import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message);
}

class UnauthenticatedFailure extends Failure {
  const UnauthenticatedFailure() : super('Please sign in to continue.');
}

class IncompleteProfileFailure extends Failure {
  const IncompleteProfileFailure(super.message);
}
