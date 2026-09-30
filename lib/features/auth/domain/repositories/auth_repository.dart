import 'package:fpdart/fpdart.dart';
import 'package:tala_trip_app/core/errors/failures.dart';
import 'package:tala_trip_app/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> signUp({
    required String username,
    required String email,
    required String password,
    required String mobileNumber,
  });

  Future<Either<Failure, UserEntity>> signIn({
    required String email,
    required String password,
  });

  Future<Either<Failure, UserEntity>> getUser();
  Future<Either<Failure, Unit>> sendVerificationEmail();
  Future<Either<Failure, bool>> isEmailVerified();
  Future<Either<Failure, Unit>> sendPasswordResetEmail(String email);

  Future<Either<Failure, Unit>> signOut();
}