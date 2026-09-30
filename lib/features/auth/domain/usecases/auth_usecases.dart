import 'package:tala_trip_app/features/auth/domain/entities/user_entity.dart';
import 'package:tala_trip_app/features/auth/domain/repositories/auth_repository.dart';

class SignUp {
  SignUp(this._repository);

  final AuthRepository _repository;

  Future<UserEntity> call({
    required String username,
    required String email,
    required String password,
    required String mobileNumber,
  }) {
    return _repository.signUp(
      username: username,
      email: email,
      password: password,
      mobileNumber: mobileNumber,
    );
  }
}

class SignIn {
  SignIn(this._repository);

  final AuthRepository _repository;

  Future<UserEntity> call({
    required String email,
    required String password,
  }) {
    return _repository.signIn(
      email: email,
      password: password,
    );
  }
}
class SendVerificationEmail {
  SendVerificationEmail(this._repository);

  final AuthRepository _repository;

  Future<void> call() => _repository.sendVerificationEmail();
}

class IsEmailVerified {
  IsEmailVerified(this._repository);

  final AuthRepository _repository;

  Future<bool> call() => _repository.isEmailVerified();
}

class GetUser {
  GetUser(this._repository);

  final AuthRepository _repository;

  Future<UserEntity> call() => _repository.getUser();
}

class SignOut {
  SignOut(this._repository);

  final AuthRepository _repository;

  Future<void> call() => _repository.signOut();
}

class SendPasswordResetEmail {
  SendPasswordResetEmail(this._repository);

  final AuthRepository _repository;

  Future<void> call(String email) {
    return _repository.sendPasswordResetEmail(email);
  }
}