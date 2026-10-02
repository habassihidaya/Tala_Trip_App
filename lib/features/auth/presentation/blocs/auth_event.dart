import 'package:fpdart/fpdart.dart';
import 'package:tala_trip_app/core/errors/failures.dart';

abstract class AuthEvent {}
class SignUpRequested extends AuthEvent {
  final String username;
  final String email;
  final String password;
  final String mobileNumber;

  SignUpRequested({
    required this.username,
    required this.email,
    required this.password,
    required this.mobileNumber});
}

class SignInRequested extends AuthEvent {
  final String email;
  final String password;

  SignInRequested({
    required this.email,
    required this.password});
}

class ResendVerificationEmailRequested extends AuthEvent {}

class CheckEmailVerificationRequested extends AuthEvent {}
class PasswordResetRequested extends AuthEvent {
  PasswordResetRequested(this.email);

  final String email;
}
class AuthSessionCheckRequested extends AuthEvent {}
class SignOutRequested extends AuthEvent {}
class AuthSessionChanged extends AuthEvent {
  AuthSessionChanged(this.result);

  final Either<Failure, String?> result;
}