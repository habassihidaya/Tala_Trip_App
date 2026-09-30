import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

import 'package:tala_trip_app/features/auth/data/data_sources/firebase_user_data_source.dart';
import 'package:tala_trip_app/features/auth/data/data_sources/user_data_source.dart';
import 'package:tala_trip_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:tala_trip_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:tala_trip_app/features/auth/domain/usecases/auth_usecases.dart';
import 'package:tala_trip_app/features/auth/presentation/blocs/auth_bloc.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  // Firebase services
  getIt.registerLazySingleton<FirebaseAuth>(
    () => FirebaseAuth.instance,
  );

  getIt.registerLazySingleton<FirebaseFirestore>(
    () => FirebaseFirestore.instance,
  );

  // Data source
  getIt.registerLazySingleton<UserDataSource>(
    () => FirebaseUserDataSource(
      getIt<FirebaseAuth>(),
      getIt<FirebaseFirestore>(),
    ),
  );

  // Repository
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      getIt<UserDataSource>(),
    ),
  );

  // Use cases
  getIt.registerLazySingleton<SignUp>(
    () => SignUp(getIt<AuthRepository>()),
  );

  getIt.registerLazySingleton<SignIn>(
    () => SignIn(getIt<AuthRepository>()),
  );

  getIt.registerLazySingleton<GetUser>(
    () => GetUser(getIt<AuthRepository>()),
  );

  getIt.registerLazySingleton<SendVerificationEmail>(
    () => SendVerificationEmail(getIt<AuthRepository>()),
  );

  getIt.registerLazySingleton<IsEmailVerified>(
    () => IsEmailVerified(getIt<AuthRepository>()),
  );

  getIt.registerLazySingleton<SendPasswordResetEmail>(
    () => SendPasswordResetEmail(getIt<AuthRepository>()),
  );

  getIt.registerLazySingleton<SignOut>(
    () => SignOut(getIt<AuthRepository>()),
  );

  // BLoC
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(
      signUp: getIt<SignUp>(),
      signIn: getIt<SignIn>(),
      getUser: getIt<GetUser>(),
      sendVerificationEmail: getIt<SendVerificationEmail>(),
      isEmailVerified: getIt<IsEmailVerified>(),
      sendPasswordResetEmail: getIt<SendPasswordResetEmail>(),
    ),
  );
}