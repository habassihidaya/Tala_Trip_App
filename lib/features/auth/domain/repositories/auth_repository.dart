import 'package:tala_trip_app/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> signUp({
    required String username,
    required String email,
    required String password,
    required String mobileNumber,
  });

  Future<UserEntity> signIn({
    required String email,
    required String password,
  });

  Future<UserEntity> getUser();
  Future<void> sendVerificationEmail();
  Future<bool> isEmailVerified();
  Future<void> sendPasswordResetEmail(String email);

  Future<void> signOut();
}