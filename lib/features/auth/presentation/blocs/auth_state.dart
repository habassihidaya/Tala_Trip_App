import 'package:tala_trip_app/features/auth/domain/entities/user_entity.dart';

abstract class AuthState{}
class AuthInitial extends AuthState{}
class AuthLoading extends AuthState{}
class AuthAuthenticated extends AuthState{
  AuthAuthenticated({required this.user});
  final UserEntity user;
}

class AuthError extends AuthState{
  AuthError({required this.message});
  final String message;
}