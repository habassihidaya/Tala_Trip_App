import 'package:tala_trip_app/features/auth/data/models/user_model.dart';
import 'package:tala_trip_app/features/auth/domain/entities/user_role.dart';

abstract class UserDataSource {
  Future<UserModel> signUp({
    required String username,
    required String email,
    required String password,
    required String mobileNumber,
    required UserRole role,
  });

  Future<UserModel> signIn({
    required String email,
    required String password,
  });

  Future<UserModel> getUser();
  Stream<String?> authStateChanges();

  Future<void> signOut();

  Future<void> sendVerificationEmail();
  Future<bool> isEmailVerified();
  Future<void> sendPasswordResetEmail(String email);
  
}