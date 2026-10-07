import 'package:tala_trip_app/features/rooms/presentation/pages/rooms_page.dart';
import 'package:go_router/go_router.dart';

import 'package:tala_trip_app/features/admin/presentation/pages/admin_dashboard_page.dart';
import 'package:tala_trip_app/features/auth/domain/entities/user_role.dart';
import 'package:tala_trip_app/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:tala_trip_app/features/auth/presentation/blocs/auth_state.dart';
import 'package:tala_trip_app/features/auth/presentation/pages/account_type_page.dart';
import 'package:tala_trip_app/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:tala_trip_app/features/onboarding/presentation/bloc/onboarding_state.dart';
import 'package:tala_trip_app/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:tala_trip_app/features/onboarding/presentation/pages/splash_page.dart';
import 'package:tala_trip_app/features/auth/presentation/pages/sign_in_page.dart';
import 'package:tala_trip_app/features/auth/presentation/pages/sign_up_page.dart';
import 'package:tala_trip_app/features/discovery/presentation/pages/traveler_home_page.dart';
import 'package:tala_trip_app/features/hotel_owner/presentation/pages/hotel_owner_dashboard_page.dart';
import 'package:tala_trip_app/features/hotels/presentation/pages/my_hotels_page.dart';
import 'package:tala_trip_app/features/hotels/presentation/pages/add_hotel_page.dart';
import 'package:tala_trip_app/features/hotels/presentation/pages/hotel_details_page.dart';
import 'package:tala_trip_app/features/admin/presentation/pages/pending_hotels_page.dart';
import 'package:tala_trip_app/features/hotels/domain/entities/hotel_entity.dart';
import 'package:tala_trip_app/features/bookings/presentation/pages/booking_form_page.dart';
import 'package:tala_trip_app/features/rooms/domain/entities/room_entity.dart';
import 'package:tala_trip_app/features/bookings/presentation/pages/my_bookings_page.dart';
import 'package:tala_trip_app/features/bookings/presentation/pages/owner_bookings_page.dart';
import 'router_refresh_notifier.dart';

GoRouter createAppRouter({
  required AuthBloc authBloc,
  required OnboardingBloc onboardingBloc,
  required RouterRefreshNotifier refreshNotifier,
  required bool Function() isSplashReady,
}) {
  bool startupResolved = false;

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final location = state.uri.path;
      // Show the splash for at least two seconds.
      if (!isSplashReady()) {
        return location == '/splash' ? null : '/splash';
      }
      final onboardingState = onboardingBloc.state;
      final authState = authBloc.state;

      final isSplash = location == '/splash';
      final isOnboarding = location == '/onboarding';

      // First, wait for the saved onboarding preference.
      // A failed check stays on SplashPage with Retry.
      if (onboardingState is OnboardingInitial ||
          onboardingState is OnboardingChecking ||
          onboardingState is OnboardingCheckFailure) {
        return isSplash ? null : '/splash';
      }

      // Keep onboarding visible until completion is saved.
      // Auth changes must not interrupt these pages.
      if (onboardingState is OnboardingRequired ||
          onboardingState is OnboardingSaving ||
          onboardingState is OnboardingSaveFailure) {
        return isOnboarding ? null : '/onboarding';
      }

      // Only continue after onboarding is completed.
      if (onboardingState is! OnboardingCompleted) {
        return isSplash ? null : '/splash';
      }

      final hasSessionResult =
          authState is AuthAuthenticated ||
          authState is AuthUnauthenticated ||
          authState is AuthVerificationRequired;

      // Wait for the initial authentication result.
      if (!startupResolved) {
        if (!hasSessionResult) {
          return isSplash ? null : '/splash';
        }

        startupResolved = true;
      }

      final isStartupPage =
          isSplash ||
          isOnboarding ||
          location == '/session-check' ||
          location == '/';

      final isTravelerRoute =
          location == '/traveler' || location.startsWith('/traveler/');

      final isOwnerRoute =
          location == '/owner' || location.startsWith('/owner/');

      final isAdminRoute =
          location == '/admin' || location.startsWith('/admin/');

      final isProtectedRoute = isTravelerRoute || isOwnerRoute || isAdminRoute;

      // Private pages require an authenticated, verified user.
      if (authState is! AuthAuthenticated) {
        if (isStartupPage) {
          if (!hasSessionResult) {
            return isSplash ? null : '/splash';
          }

          return '/sign-in';
        }

        if (isProtectedRoute) {
          return '/sign-in';
        }

        // Keep existing sign-in, registration and verification behavior.
        return null;
      }

      final role = authState.user.role;

      final homePath = switch (role) {
        UserRole.traveler => '/traveler',
        UserRole.hotelOwner => '/owner',
        UserRole.admin => '/admin',
      };

      final isAuthPage =
          location == '/sign-in' ||
          location == '/sign-up' ||
          location == '/account-type';

      if (isStartupPage || isAuthPage) {
        return homePath;
      }

      // Prevent access to another role's private area.
      final wrongRole =
          (isTravelerRoute && role != UserRole.traveler) ||
          (isOwnerRoute && role != UserRole.hotelOwner) ||
          (isAdminRoute && role != UserRole.admin);

      if (wrongRole) {
        return homePath;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/traveler/hotels/:hotelId',
        builder: (context, state) =>
            HotelDetailsPage(hotelId: state.pathParameters['hotelId']!),
      ),
      for (final role in ['owner', 'traveler', 'admin'])
        GoRoute(
          path: '/$role/hotels/:hotelId/rooms',
          builder: (context, state) =>
              RoomsPage(hotelId: state.pathParameters['hotelId']!),
        ),

      GoRoute(path: '/', redirect: (context, state) => '/session-check'),
      GoRoute(path: '/', redirect: (context, state) => '/splash'),
      GoRoute(path: '/session-check', redirect: (context, state) => '/splash'),
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SignInPage(),
      ),
      GoRoute(
        path: '/account-type',
        builder: (context, state) => const AccountTypePage(),
      ),
      GoRoute(
        path: '/sign-up',
        redirect: (context, state) {
          final role = state.uri.queryParameters['role'];

          // Only these two roles are available for registration.
          if (role != 'traveler' && role != 'hotelOwner') {
            return '/account-type';
          }

          return null;
        },
        builder: (context, state) {
          final role = state.uri.queryParameters['role'] == 'hotelOwner'
              ? UserRole.hotelOwner
              : UserRole.traveler;

          return SignUpPage(role: role);
        },
      ),
      GoRoute(
        path: '/traveler/bookings',
        builder: (context, state) => const MyBookingsPage(),
      ),

      GoRoute(
        path: '/owner/bookings',
        builder: (context, state) => const OwnerBookingsPage(),
      ),
      GoRoute(
        path: '/traveler',
        builder: (context, state) => const TravelerHomePage(),
      ),
      GoRoute(
        path: '/owner',
        builder: (context, state) => const HotelOwnerDashboardPage(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardPage(),
      ),
      GoRoute(
        path: '/owner/hotels',
        builder: (context, state) => const MyHotelsPage(),
      ),
      GoRoute(
        path: '/owner/hotels/add',
        builder: (context, state) => const AddHotelPage(),
      ),
      GoRoute(
        path: '/owner/hotels/:hotelId',
        builder: (context, state) {
          return HotelDetailsPage(hotelId: state.pathParameters['hotelId']!);
        },
      ),
      GoRoute(
        path: '/admin/hotels',
        builder: (context, state) => const PendingHotelsPage(),
      ),
      GoRoute(
        path: '/admin/hotels/:hotelId',
        builder: (context, state) {
          return HotelDetailsPage(hotelId: state.pathParameters['hotelId']!);
        },
      ),
      GoRoute(
        path: '/owner/hotels/:hotelId/edit',
        redirect: (context, state) {
          final hotel = state.extra;

          // If the form data is missing or stale, return to details.
          if (hotel is! HotelEntity ||
              hotel.id != state.pathParameters['hotelId'] ||
              (hotel.status.name != 'draft' &&
                  hotel.status.name != 'rejected')) {
            final id = Uri.encodeComponent(state.pathParameters['hotelId']!);
            return '/owner/hotels/$id';
          }

          return null;
        },
        builder: (context, state) {
          return AddHotelPage(hotel: state.extra as HotelEntity);
        },
      ),
      GoRoute(
        path: '/traveler/hotels/:hotelId/book/:roomType',
        redirect: (context, state) {
          final roomTypeName = state.pathParameters['roomType'];

          final validRoomType = RoomType.values.any(
            (roomType) => roomType.name == roomTypeName,
          );

          return validRoomType ? null : '/traveler';
        },
        builder: (context, state) {
          final roomTypeName = state.pathParameters['roomType']!;

          final roomType = RoomType.values.firstWhere(
            (item) => item.name == roomTypeName,
          );

          return BookingFormPage(
            hotelId: state.pathParameters['hotelId']!,
            roomType: roomType,
          );
        },
      ),
    ],
  );
}
