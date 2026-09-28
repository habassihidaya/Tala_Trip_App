import 'package:tala_trip_app/features/auth/data/models/user_model.dart';

abstract class UserDataSource {
  Future<UserModel> signUp({
    required String username,
    required String email,
    required String password,
    required String mobileNumber,
  });

  Future<UserModel> signIn({
    required String email,
    required String password,
  });

  Future<UserModel> getUser();

  Future<void> signOut();
}