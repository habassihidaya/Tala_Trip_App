import 'package:tala_trip_app/features/auth/domain/entities/user_entity.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  AuthAuthenticated({
    required this.user,
    this.isSigningOut = false,
    this.signOutError,
  });

  final UserEntity user;
  final bool isSigningOut;
  final String? signOutError;
}

class AuthError extends AuthState {
  AuthError({required this.message});
  final String message;
}

class AuthVerificationRequired extends AuthState {
  AuthVerificationRequired({required this.user, this.message});

  final UserEntity user;
  final String? message;
}

class AuthPasswordResetEmailSent extends AuthState {}

class AuthUnauthenticated extends AuthState {}

/// Recoverable account setup error; existing forms keep their error handling.
class AuthProfileRequired extends AuthError {
  AuthProfileRequired({required super.message});
}
