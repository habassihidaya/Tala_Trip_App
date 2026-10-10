import 'package:fpdart/fpdart.dart';

import 'package:tala_trip_app/core/errors/failures.dart';
import 'package:tala_trip_app/features/auth/domain/entities/user_entity.dart';
import 'package:tala_trip_app/features/auth/domain/entities/user_role.dart';

abstract class AuthEvent {}

class SignUpRequested extends AuthEvent {
  final String username;
  final String email;
  final String password;
  final String mobileNumber;
  final UserRole role;

  SignUpRequested({
    required this.username,
    required this.email,
    required this.password,
    required this.mobileNumber,
    required this.role,
  });
}

class SignInRequested extends AuthEvent {
  final String email;
  final String password;

  SignInRequested({required this.email, required this.password});
}

class ResendVerificationEmailRequested extends AuthEvent {}

class CheckEmailVerificationRequested extends AuthEvent {}

class PasswordResetRequested extends AuthEvent {
  final String email;

  PasswordResetRequested(this.email);
}

class AuthSessionCheckRequested extends AuthEvent {}

class SignOutRequested extends AuthEvent {}

class AuthSessionChanged extends AuthEvent {
  final Either<Failure, String?> result;

  AuthSessionChanged(this.result);
}

class AuthUserProfileUpdated extends AuthEvent {
  final UserEntity user;

  AuthUserProfileUpdated({required this.user});
}
