import 'package:tala_trip_app/features/rooms/data/data_sources/room_data_source.dart';
import 'package:tala_trip_app/features/rooms/data/data_sources/firebase_room_data_source.dart';
import 'package:tala_trip_app/features/rooms/data/repositories/room_repository_impl.dart';
import 'package:tala_trip_app/features/rooms/domain/repositories/room_repository.dart';
import 'package:tala_trip_app/features/rooms/domain/usecases/room_usecases.dart';
import 'package:tala_trip_app/features/rooms/presentation/bloc/room_bloc.dart';
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

import 'package:tala_trip_app/core/time/algeria_time.dart';

import 'package:tala_trip_app/features/bookings/data/data_sources/booking_data_source.dart';
import 'package:tala_trip_app/features/bookings/data/data_sources/booking_submission_local_data_source.dart';
import 'package:tala_trip_app/features/bookings/data/data_sources/sqlite_booking_submission_local_data_source.dart';
import 'package:tala_trip_app/features/bookings/data/data_sources/firebase_booking_reader.dart';
import 'package:tala_trip_app/features/bookings/data/data_sources/firebase_booking_availability.dart';
import 'package:tala_trip_app/features/bookings/data/data_sources/firebase_booking_submitter.dart';
import 'package:tala_trip_app/features/bookings/data/data_sources/firebase_booking_recovery.dart';
import 'package:tala_trip_app/features/bookings/data/data_sources/firebase_booking_actions.dart';
import 'package:tala_trip_app/features/bookings/data/data_sources/firebase_booking_data_source.dart';

import 'package:tala_trip_app/features/bookings/data/repositories/booking_repository_impl.dart';
import 'package:tala_trip_app/features/bookings/domain/repositories/booking_repository.dart';
import 'package:tala_trip_app/features/bookings/domain/usecases/booking_usecases.dart';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:tala_trip_app/core/network/network_info.dart';
import 'package:tala_trip_app/features/bookings/presentation/bloc/booking_form_bloc.dart';
import 'package:tala_trip_app/features/rooms/domain/entities/room_entity.dart';

import 'package:tala_trip_app/features/bookings/presentation/bloc/booking_list_bloc.dart';
import 'package:tala_trip_app/features/bookings/presentation/bloc/booking_list_event.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:tala_trip_app/features/onboarding/data/data_sources/onboarding_local_data_source.dart';
import 'package:tala_trip_app/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:tala_trip_app/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:tala_trip_app/features/onboarding/domain/usecases/onboarding_usecases.dart';
import 'package:tala_trip_app/features/onboarding/presentation/bloc/onboarding_bloc.dart';

import 'package:tala_trip_app/features/profile/data/data_sources/profile_data_source.dart';
import 'package:tala_trip_app/features/profile/data/data_sources/firebase_profile_data_source.dart';
import 'package:tala_trip_app/features/profile/data/data_sources/profile_photo_data_source.dart';
import 'package:tala_trip_app/features/profile/data/data_sources/cloudinary_profile_photo_data_source.dart';
import 'package:tala_trip_app/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:tala_trip_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:tala_trip_app/features/profile/domain/usecases/profile_usecases.dart';
import 'package:tala_trip_app/features/profile/presentation/bloc/profile_bloc.dart';

import 'package:tala_trip_app/features/favorites/data/data_sources/favorites_data_source.dart';
import 'package:tala_trip_app/features/favorites/data/data_sources/local_favorites_data_source.dart';
import 'package:tala_trip_app/features/favorites/data/repositories/favorites_repository_impl.dart';
import 'package:tala_trip_app/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:tala_trip_app/features/favorites/domain/usecases/favorites_usecases.dart';
import 'package:tala_trip_app/features/favorites/presentation/bloc/favorites_bloc.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // Firebase services
  getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);

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
    () => AuthRepositoryImpl(getIt<UserDataSource>()),
  );

  // Use cases
  getIt.registerLazySingleton<SignUp>(() => SignUp(getIt<AuthRepository>()));

  getIt.registerLazySingleton<SignIn>(() => SignIn(getIt<AuthRepository>()));

  getIt.registerLazySingleton<GetUser>(() => GetUser(getIt<AuthRepository>()));

  getIt.registerLazySingleton<SendVerificationEmail>(
    () => SendVerificationEmail(getIt<AuthRepository>()),
  );

  getIt.registerLazySingleton<IsEmailVerified>(
    () => IsEmailVerified(getIt<AuthRepository>()),
  );

  getIt.registerLazySingleton<SendPasswordResetEmail>(
    () => SendPasswordResetEmail(getIt<AuthRepository>()),
  );

  getIt.registerLazySingleton<SignOut>(() => SignOut(getIt<AuthRepository>()));
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
  // Profile: Firestore data source.
  getIt.registerLazySingleton<ProfileDataSource>(
    () => FirebaseProfileDataSource(
      auth: getIt<FirebaseAuth>(),
      firestore: getIt<FirebaseFirestore>(),
    ),
  );

  // Profile: Cloudinary photo uploader.
  getIt.registerLazySingleton<ProfilePhotoDataSource>(
    () => CloudinaryProfilePhotoDataSource(
      client: getIt<http.Client>(),
      cloudName: 'lbkc13qt',
      uploadPreset: 'tala_hotels',
    ),
  );

  // Profile: repository.
  getIt.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(
      dataSource: getIt<ProfileDataSource>(),
      photoDataSource: getIt<ProfilePhotoDataSource>(),
    ),
  );

  // Profile: use cases.
  getIt.registerLazySingleton<GetProfile>(
    () => GetProfile(getIt<ProfileRepository>()),
  );

  getIt.registerLazySingleton<UpdateProfileName>(
    () => UpdateProfileName(getIt<ProfileRepository>()),
  );

  getIt.registerLazySingleton<UpdateProfilePhoto>(
    () => UpdateProfilePhoto(getIt<ProfileRepository>()),
  );

  // Profile: a fresh BLoC for each profile page.
  getIt.registerFactory<ProfileBloc>(
    () => ProfileBloc(
      getProfile: getIt<GetProfile>(),
      updateProfileName: getIt<UpdateProfileName>(),
      updateProfilePhoto: getIt<UpdateProfilePhoto>(),
    ),
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
    () => HotelPhotoRepositoryImpl(getIt<HotelPhotoDataSource>()),
  );

  // Photo upload use case.
  getIt.registerLazySingleton<UploadHotelPhoto>(
    () => UploadHotelPhoto(getIt<HotelPhotoRepository>()),
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
  getIt.registerLazySingleton<RoomDataSource>(
    () => FirebaseRoomDataSource(
      getIt<FirebaseAuth>(),
      getIt<FirebaseFirestore>(),
    ),
  );
  getIt.registerLazySingleton<RoomRepository>(
    () => RoomRepositoryImpl(getIt<RoomDataSource>()),
  );
  getIt.registerLazySingleton<GetRooms>(
    () => GetRooms(getIt<RoomRepository>()),
  );
  getIt.registerLazySingleton<SaveRoom>(
    () => SaveRoom(getIt<RoomRepository>()),
  );
  getIt.registerLazySingleton<DeleteRoom>(
    () => DeleteRoom(getIt<RoomRepository>()),
  );
  getIt.registerFactoryParam<RoomBloc, String, void>(
    (hotelId, _) => RoomBloc(
      hotelId,
      getIt<GetRooms>(),
      getIt<SaveRoom>(),
      getIt<DeleteRoom>(),
    ),
  );
  // Bookings: Algeria's calendar dates and local time.
  getIt.registerLazySingleton<AlgeriaTime>(() => AlgeriaTime.initialize());

  // Bookings: open local storage before starting the app.
  final bookingLocalDataSource =
      await SqliteBookingSubmissionLocalDataSource.open();

  getIt.registerSingleton<BookingSubmissionLocalDataSource>(
    bookingLocalDataSource,
    dispose: (_) => bookingLocalDataSource.close(),
  );

  // Bookings: Firebase helpers.
  getIt.registerLazySingleton<FirebaseBookingReader>(
    () => FirebaseBookingReader(
      getIt<FirebaseAuth>(),
      getIt<FirebaseFirestore>(),
    ),
  );

  getIt.registerLazySingleton<FirebaseBookingAvailability>(
    () => FirebaseBookingAvailability(
      getIt<FirebaseAuth>(),
      getIt<FirebaseFirestore>(),
      getIt<AlgeriaTime>(),
    ),
  );

  getIt.registerLazySingleton<FirebaseBookingSubmitter>(
    () => FirebaseBookingSubmitter(
      getIt<FirebaseAuth>(),
      getIt<FirebaseFirestore>(),
      getIt<FirebaseBookingReader>(),
      getIt<AlgeriaTime>(),
    ),
  );

  getIt.registerLazySingleton<FirebaseBookingRecovery>(
    () => FirebaseBookingRecovery(
      getIt<FirebaseAuth>(),
      getIt<FirebaseFirestore>(),
      getIt<FirebaseBookingReader>(),
    ),
  );

  getIt.registerLazySingleton<FirebaseBookingActions>(
    () => FirebaseBookingActions(
      getIt<FirebaseAuth>(),
      getIt<FirebaseFirestore>(),
      getIt<FirebaseBookingReader>(),
      getIt<AlgeriaTime>(),
    ),
  );

  // Bookings: combine the helpers behind one data source.
  getIt.registerLazySingleton<BookingDataSource>(
    () => FirebaseBookingDataSource(
      reader: getIt<FirebaseBookingReader>(),
      availability: getIt<FirebaseBookingAvailability>(),
      submitter: getIt<FirebaseBookingSubmitter>(),
      recovery: getIt<FirebaseBookingRecovery>(),
      actions: getIt<FirebaseBookingActions>(),
    ),
  );

  // Bookings: one shared repository for submission coordination.
  getIt.registerLazySingleton<BookingRepository>(
    () => BookingRepositoryImpl(
      getIt<BookingDataSource>(),
      getIt<BookingSubmissionLocalDataSource>(),
    ),
  );

  // Bookings: use cases.
  getIt.registerLazySingleton<CheckBookingAvailability>(
    () => CheckBookingAvailability(getIt<BookingRepository>()),
  );

  getIt.registerLazySingleton<PrepareBookingSubmission>(
    () => PrepareBookingSubmission(getIt<BookingRepository>()),
  );

  getIt.registerLazySingleton<SubmitBooking>(
    () => SubmitBooking(getIt<BookingRepository>()),
  );

  getIt.registerLazySingleton<ResolveBookingSubmission>(
    () => ResolveBookingSubmission(getIt<BookingRepository>()),
  );

  getIt.registerLazySingleton<GetUnresolvedBookingSubmissions>(
    () => GetUnresolvedBookingSubmissions(getIt<BookingRepository>()),
  );

  getIt.registerLazySingleton<GetMyBookings>(
    () => GetMyBookings(getIt<BookingRepository>()),
  );

  getIt.registerLazySingleton<GetOwnerBookings>(
    () => GetOwnerBookings(getIt<BookingRepository>()),
  );

  getIt.registerLazySingleton<GetBookingById>(
    () => GetBookingById(getIt<BookingRepository>()),
  );

  getIt.registerLazySingleton<AcceptBooking>(
    () => AcceptBooking(getIt<BookingRepository>()),
  );

  getIt.registerLazySingleton<RejectBooking>(
    () => RejectBooking(getIt<BookingRepository>()),
  );

  getIt.registerLazySingleton<CancelBooking>(
    () => CancelBooking(getIt<BookingRepository>()),
  );
  // Booking form network check.
  getIt.registerLazySingleton<NetworkInfo>(
    () => ConnectivityNetworkInfo(Connectivity()),
  );

  // A new form BLoC for each hotel and room page.
  getIt.registerFactoryParam<BookingFormBloc, String, RoomType>(
    (hotelId, roomType) => BookingFormBloc(
      hotelId: hotelId,
      roomType: roomType,
      checkAvailability: getIt<CheckBookingAvailability>(),
      prepareSubmission: getIt<PrepareBookingSubmission>(),
      submitBooking: getIt<SubmitBooking>(),
      resolveSubmission: getIt<ResolveBookingSubmission>(),
      getUnresolvedSubmissions: getIt<GetUnresolvedBookingSubmissions>(),
      networkInfo: getIt<NetworkInfo>(),
      algeriaTime: getIt<AlgeriaTime>(),
    ),
  );
  // Booking lists: a separate BLoC for travelers and owners.
  getIt.registerFactoryParam<BookingListBloc, BookingListAudience, void>(
    (audience, _) => BookingListBloc(
      audience: audience,
      getMyBookings: getIt<GetMyBookings>(),
      getOwnerBookings: getIt<GetOwnerBookings>(),
      acceptBooking: getIt<AcceptBooking>(),
      rejectBooking: getIt<RejectBooking>(),
      cancelBooking: getIt<CancelBooking>(),
    ),
  );

  // Onboarding: local preferences.
  getIt.registerLazySingleton<SharedPreferencesAsync>(
    () => SharedPreferencesAsync(),
  );

  // Onboarding: data source.
  getIt.registerLazySingleton<OnboardingLocalDataSource>(
    () => OnboardingLocalDataSource(getIt<SharedPreferencesAsync>()),
  );

  // Onboarding: repository.
  getIt.registerLazySingleton<OnboardingRepository>(
    () => OnboardingRepositoryImpl(getIt<OnboardingLocalDataSource>()),
  );

  // Onboarding: use cases.
  getIt.registerLazySingleton<CheckOnboardingCompleted>(
    () => CheckOnboardingCompleted(getIt<OnboardingRepository>()),
  );

  getIt.registerLazySingleton<CompleteOnboarding>(
    () => CompleteOnboarding(getIt<OnboardingRepository>()),
  );

  // Onboarding: BLoC.
  getIt.registerFactory<OnboardingBloc>(
    () => OnboardingBloc(
      getIt<CheckOnboardingCompleted>(),
      getIt<CompleteOnboarding>(),
    ),
  );

  // Favorites: local storage.
  final favoritesPreferences = await SharedPreferences.getInstance();

  getIt.registerLazySingleton<FavoritesDataSource>(
    () => LocalFavoritesDataSource(favoritesPreferences),
  );

  // Favorites: repository.
  getIt.registerLazySingleton<FavoritesRepository>(
    () => FavoritesRepositoryImpl(
      getIt<FavoritesDataSource>(),
      getIt<HotelRepository>(),
      getIt<FirebaseAuth>(),
    ),
  );

  // Favorites: use cases.
  getIt.registerLazySingleton<GetFavoriteIds>(
    () => GetFavoriteIds(getIt<FavoritesRepository>()),
  );

  getIt.registerLazySingleton<GetFavoriteHotels>(
    () => GetFavoriteHotels(getIt<FavoritesRepository>()),
  );

  getIt.registerLazySingleton<AddFavorite>(
    () => AddFavorite(getIt<FavoritesRepository>()),
  );

  getIt.registerLazySingleton<RemoveFavorite>(
    () => RemoveFavorite(getIt<FavoritesRepository>()),
  );
  getIt.registerFactory<FavoritesBloc>(
    () => FavoritesBloc(
      getFavoriteIds: getIt<GetFavoriteIds>(),
      getFavoriteHotels: getIt<GetFavoriteHotels>(),
      addFavorite: getIt<AddFavorite>(),
      removeFavorite: getIt<RemoveFavorite>(),
    ),
  );
}
