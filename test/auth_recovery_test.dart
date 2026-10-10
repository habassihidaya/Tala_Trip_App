import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:tala_trip_app/core/errors/exceptions.dart';
import 'package:tala_trip_app/core/errors/failure_mapper.dart';
import 'package:tala_trip_app/core/errors/failures.dart';
import 'package:tala_trip_app/features/auth/domain/entities/user_entity.dart';
import 'package:tala_trip_app/features/auth/domain/entities/user_role.dart';
import 'package:tala_trip_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:tala_trip_app/features/auth/domain/usecases/auth_usecases.dart';
import 'package:tala_trip_app/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:tala_trip_app/features/auth/presentation/blocs/auth_event.dart';
import 'package:tala_trip_app/features/auth/presentation/blocs/auth_state.dart';

class _Repository implements AuthRepository {
  bool missing = true;
  bool verified = false;

  final user = const UserEntity(
    id: 'user',
    username: 'Traveler',
    email: 'user@example.com',
    mobileNumber: '+33612345678',
    role: UserRole.traveler,
  );

  @override
  Stream<Either<Failure, String?>> authStateChanges() {
    return const Stream.empty();
  }

  @override
  Future<Either<Failure, UserEntity>> getUser() async {
    if (missing) {
      return Left(mapExceptionToFailure(const UserProfileNotFoundException()));
    }

    return Right(user);
  }

  @override
  Future<Either<Failure, UserEntity>> signUp({
    required String username,
    required String email,
    required String password,
    required String mobileNumber,
    required UserRole role,
  }) async {
    if (missing) {
      return Left(
        mapExceptionToFailure(const UserProfileSetupPendingException()),
      );
    }

    return Right(user);
  }

  @override
  Future<Either<Failure, UserEntity>> signIn({
    required String email,
    required String password,
  }) async {
    return Right(user);
  }

  @override
  Future<Either<Failure, bool>> isEmailVerified() async {
    return Right(verified);
  }

  @override
  Future<Either<Failure, Unit>> sendVerificationEmail() async {
    return Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> sendPasswordResetEmail(String email) async {
    return Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> signOut() async {
    return Right(unit);
  }
}

AuthBloc _createBloc(_Repository repository) {
  return AuthBloc(
    signUp: SignUp(repository),
    signIn: SignIn(repository),
    watchAuthState: WatchAuthState(repository),
    getUser: GetUser(repository),
    sendVerificationEmail: SendVerificationEmail(repository),
    isEmailVerified: IsEmailVerified(repository),
    sendPasswordResetEmail: SendPasswordResetEmail(repository),
    signOut: SignOut(repository),
  );
}

void main() {
  test(
    'missing profile at startup produces a recoverable session result',
    () async {
      final bloc = _createBloc(_Repository());
      addTearDown(bloc.close);

      final result = bloc.stream.firstWhere(
        (state) => state is AuthProfileRequired,
      );

      bloc.add(AuthSessionChanged(const Right('user')));

      expect(await result, isA<AuthProfileRequired>());
    },
  );

  test(
    'failed profile setup can retry without losing verification requirement',
    () async {
      final repository = _Repository();
      final bloc = _createBloc(repository);
      addTearDown(bloc.close);

      SignUpRequested request() {
        return SignUpRequested(
          username: 'Traveler',
          email: 'user@example.com',
          password: 'strong test passphrase',
          mobileNumber: '+33612345678',
          role: UserRole.traveler,
        );
      }

      final failed = bloc.stream.firstWhere(
        (state) => state is AuthProfileRequired,
      );

      bloc.add(request());
      await failed;

      repository.missing = false;

      final recovered = bloc.stream.firstWhere(
        (state) => state is AuthVerificationRequired,
      );

      bloc.add(request());

      expect(await recovered, isA<AuthVerificationRequired>());
    },
  );

  test(
    'recovering an already verified account enters authenticated state',
    () async {
      final repository = _Repository()
        ..missing = false
        ..verified = true;

      final bloc = _createBloc(repository);
      addTearDown(bloc.close);

      final result = bloc.stream.firstWhere(
        (state) => state is AuthAuthenticated,
      );

      bloc.add(
        SignUpRequested(
          username: 'Traveler',
          email: 'user@example.com',
          password: 'strong test passphrase',
          mobileNumber: '+33612345678',
          role: UserRole.traveler,
        ),
      );

      expect(await result, isA<AuthAuthenticated>());
    },
  );
}
