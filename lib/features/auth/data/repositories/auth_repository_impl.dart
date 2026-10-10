import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:tala_trip_app/core/errors/failure_mapper.dart';
import 'package:tala_trip_app/core/errors/failures.dart';
import 'package:tala_trip_app/features/auth/data/data_sources/user_data_source.dart';
import 'package:tala_trip_app/features/auth/domain/entities/user_entity.dart';
import 'package:tala_trip_app/features/auth/domain/entities/user_role.dart';
import 'package:tala_trip_app/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._dataSource);

  final UserDataSource _dataSource;

  @override
  Future<Either<Failure, UserEntity>> signUp({
    required String username,
    required String email,
    required String password,
    required String mobileNumber,
    required UserRole role,
  }) async {
    try {
      final model = await _dataSource.signUp(
        username: username,
        email: email,
        password: password,
        mobileNumber: mobileNumber,
        role: role,
      );

      return Right(model.toEntity());
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final model = await _dataSource.signIn(email: email, password: password);

      return Right(model.toEntity());
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getUser() async {
    try {
      final model = await _dataSource.getUser();

      return Right(model.toEntity());
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, Unit>> sendVerificationEmail() async {
    try {
      await _dataSource.sendVerificationEmail();

      return Right(unit);
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, bool>> isEmailVerified() async {
    try {
      final verified = await _dataSource.isEmailVerified();

      return Right(verified);
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, Unit>> sendPasswordResetEmail(String email) async {
    try {
      await _dataSource.sendPasswordResetEmail(email);

      return Right(unit);
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, Unit>> signOut() async {
    try {
      await _dataSource.signOut();

      return Right(unit);
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Stream<Either<Failure, String?>> authStateChanges() {
    try {
      return _dataSource.authStateChanges().transform(
        StreamTransformer<String?, Either<Failure, String?>>.fromHandlers(
          handleData: (userId, sink) {
            sink.add(Right(userId));
          },
          handleError: (error, stackTrace, sink) {
            sink.add(Left(mapExceptionToFailure(error)));
          },
        ),
      );
    } catch (error) {
      return Stream<Either<Failure, String?>>.value(
        Left(mapExceptionToFailure(error)),
      );
    }
  }
}
