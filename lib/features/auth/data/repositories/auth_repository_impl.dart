import 'package:tala_trip_app/features/auth/data/data_sources/user_data_source.dart';
import 'package:tala_trip_app/features/auth/domain/entities/user_entity.dart';
import 'package:tala_trip_app/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._dataSource);

  final UserDataSource _dataSource;

  @override
  Future<UserEntity> signUp({
    required String username,
    required String email,
    required String password,
    required String mobileNumber,
  }) async {
    final model = await _dataSource.signUp(
      username: username,
      email: email,
      password: password,
      mobileNumber: mobileNumber,
    );
    return model.toEntity();
  }

  @override
  Future<UserEntity> signIn({
    required String email,
    required String password,
  }) async {
    final model = await _dataSource.signIn(
      email: email,
      password: password,
    );
    return model.toEntity();
  }

  @override
  Future<UserEntity> getUser() async {
    final model = await _dataSource.getUser();
    return model.toEntity();
  }

  @override
Future<void> sendVerificationEmail() {
  return _dataSource.sendVerificationEmail();
}

@override
Future<bool> isEmailVerified() {
  return _dataSource.isEmailVerified();
}

@override
Future<void> sendPasswordResetEmail(String email) {
  return _dataSource.sendPasswordResetEmail(email);
}



  @override
  Future<void> signOut() => _dataSource.signOut();
}