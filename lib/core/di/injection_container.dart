import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

import 'package:tala_trip_app/features/auth/data/data_sources/firebase_user_data_source.dart';
import 'package:tala_trip_app/features/auth/data/data_sources/user_data_source.dart';
import 'package:tala_trip_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:tala_trip_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:tala_trip_app/features/auth/domain/usecases/auth_usecases.dart';
import 'package:tala_trip_app/features/auth/presentation/blocs/auth_bloc.dart';

import 'package:tala_trip_app/features/hotels/data/data_sources/hotel_data_sources.dart';
import 'package:tala_trip_app/features/hotels/data/data_sources/firebase_hotel_data_sources.dart';
import 'package:tala_trip_app/features/hotels/data/repositories/hotel_repository_impl.dart';
import 'package:tala_trip_app/features/hotels/domain/repositories/hotel_repository.dart';
import 'package:tala_trip_app/features/hotels/domain/usecases/hotel_usecases.dart';
import 'package:tala_trip_app/features/hotels/presentation/bloc/hotel_bloc.dart';

import 'package:http/http.dart' as http;

import 'package:tala_trip_app/features/hotels/data/data_sources/cloudinary_hotel_photo_data_source.dart';
import 'package:tala_trip_app/features/hotels/data/data_sources/hotel_photo_data_source.dart';
import 'package:tala_trip_app/features/hotels/data/repositories/hotel_photo_repository_impl.dart';
import 'package:tala_trip_app/features/hotels/domain/repositories/hotel_photo_repository.dart';
import 'package:tala_trip_app/features/hotels/domain/usecases/upload_hotel_photo.dart';


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
  getIt.registerLazySingleton<WatchAuthState>(
  () => WatchAuthState(getIt<AuthRepository>()),
  );

  // BLoC
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(
      signUp: getIt<SignUp>(),
      signIn: getIt<SignIn>(),
       signOut: getIt<SignOut>(),
       watchAuthState: getIt<WatchAuthState>(),
      getUser: getIt<GetUser>(),
      sendVerificationEmail: getIt<SendVerificationEmail>(),
      isEmailVerified: getIt<IsEmailVerified>(),
      sendPasswordResetEmail: getIt<SendPasswordResetEmail>(),
    ),
  );
  // Hotels: data source.
getIt.registerLazySingleton<HotelDataSource>(
  () => FirebaseHotelDataSource(
    getIt<FirebaseAuth>(),
    getIt<FirebaseFirestore>(),
  ),
);

// Hotels: repository.
getIt.registerLazySingleton<HotelRepository>(
  () => HotelRepositoryImpl(getIt<HotelDataSource>()),
);

// Hotels: use cases.
getIt.registerLazySingleton<CreateHotelDraft>(
  () => CreateHotelDraft(getIt<HotelRepository>()),
);

getIt.registerLazySingleton<GetMyHotels>(
  () => GetMyHotels(getIt<HotelRepository>()),
);

getIt.registerLazySingleton<GetHotelById>(
  () => GetHotelById(getIt<HotelRepository>()),
);

getIt.registerLazySingleton<UpdateHotelDraft>(
  () => UpdateHotelDraft(getIt<HotelRepository>()),
);

getIt.registerLazySingleton<DeleteHotelDraft>(
  () => DeleteHotelDraft(getIt<HotelRepository>()),
);

getIt.registerLazySingleton<SubmitHotelForReview>(
  () => SubmitHotelForReview(getIt<HotelRepository>()),
);

getIt.registerLazySingleton<GetPendingHotels>(
  () => GetPendingHotels(getIt<HotelRepository>()),
);

getIt.registerLazySingleton<ApproveHotel>(
  () => ApproveHotel(getIt<HotelRepository>()),
);

getIt.registerLazySingleton<RejectHotel>(
  () => RejectHotel(getIt<HotelRepository>()),
);

getIt.registerLazySingleton<GetApprovedHotels>(
  () => GetApprovedHotels(getIt<HotelRepository>()),
);
 // HTTP client for uploading photos.
getIt.registerLazySingleton<http.Client>(
  () => http.Client(),
  dispose: (client) => client.close(),
);

// Photo data source.
getIt.registerLazySingleton<HotelPhotoDataSource>(
  () => CloudinaryHotelPhotoDataSource(
    client: getIt<http.Client>(),
    cloudName: 'lbkc13qt',
    uploadPreset: 'tala_hotels',
  ),
);

// Photo repository.
getIt.registerLazySingleton<HotelPhotoRepository>(
  () => HotelPhotoRepositoryImpl(
    getIt<HotelPhotoDataSource>(),
  ),
);

// Photo upload use case.
getIt.registerLazySingleton<UploadHotelPhoto>(
  () => UploadHotelPhoto(
    getIt<HotelPhotoRepository>(),
  ),
);

// Hotels: a fresh BLoC for each requesting page.
getIt.registerFactory<HotelBloc>(
  () => HotelBloc(
    uploadHotelPhoto: getIt<UploadHotelPhoto>(),
    createHotelDraft: getIt<CreateHotelDraft>(),
    getMyHotels: getIt<GetMyHotels>(),
    getHotelById: getIt<GetHotelById>(),
    updateHotelDraft: getIt<UpdateHotelDraft>(),
    deleteHotelDraft: getIt<DeleteHotelDraft>(),
    submitHotelForReview: getIt<SubmitHotelForReview>(),
    getPendingHotels: getIt<GetPendingHotels>(),
    approveHotel: getIt<ApproveHotel>(),
    rejectHotel: getIt<RejectHotel>(),
    getApprovedHotels: getIt<GetApprovedHotels>(),
  ),
);
}