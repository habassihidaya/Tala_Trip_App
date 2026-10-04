import 'package:go_router/go_router.dart';

import 'package:tala_trip_app/features/admin/presentation/pages/admin_dashboard_page.dart';
import 'package:tala_trip_app/features/auth/domain/entities/user_role.dart';
import 'package:tala_trip_app/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:tala_trip_app/features/auth/presentation/blocs/auth_state.dart';
import 'package:tala_trip_app/features/auth/presentation/pages/account_type_page.dart';
import 'package:tala_trip_app/features/auth/presentation/pages/session_check_page.dart';
import 'package:tala_trip_app/features/auth/presentation/pages/sign_in_page.dart';
import 'package:tala_trip_app/features/auth/presentation/pages/sign_up_page.dart';
import 'package:tala_trip_app/features/discovery/presentation/pages/traveler_home_page.dart';
import 'package:tala_trip_app/features/hotel_owner/presentation/pages/hotel_owner_dashboard_page.dart';
import 'package:tala_trip_app/features/hotels/presentation/pages/my_hotels_page.dart';
import 'package:tala_trip_app/features/hotels/presentation/pages/add_hotel_page.dart';
import 'package:tala_trip_app/features/hotels/presentation/pages/hotel_details_page.dart';
import 'package:tala_trip_app/features/admin/presentation/pages/pending_hotels_page.dart';
import 'package:tala_trip_app/features/hotels/domain/entities/hotel_entity.dart';
import 'router_refresh_notifier.dart';

GoRouter createAppRouter({
  required AuthBloc authBloc,
  required RouterRefreshNotifier refreshNotifier,
}) {
  bool startupResolved = false;

  return GoRouter(
    initialLocation: '/session-check',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = authBloc.state;
      final location = state.uri.path;
      final isSessionCheck = location == '/session-check';

      final hasSessionResult =
          authState is AuthAuthenticated ||
          authState is AuthUnauthenticated ||
          authState is AuthVerificationRequired;

      // Wait for the initial session check.
      // Startup errors stay on the session-check page with Retry.
      if (!startupResolved) {
        if (!hasSessionResult) {
          return isSessionCheck ? null : '/session-check';
        }

        startupResolved = true;
      }

      final isTravelerRoute =
          location == '/traveler' ||
          location.startsWith('/traveler/');

      final isOwnerRoute =
          location == '/owner' ||
          location.startsWith('/owner/');

      final isAdminRoute =
          location == '/admin' ||
          location.startsWith('/admin/');

      final isProtectedRoute =
          isTravelerRoute || isOwnerRoute || isAdminRoute;

      // Require an authenticated, verified session for private pages.
      if (authState is! AuthAuthenticated) {
        if (isSessionCheck) {
          return hasSessionResult ? '/sign-in' : null;
        }

        if (isProtectedRoute || location == '/') {
          return '/sign-in';
        }

        // Email verification is currently handled on SignInPage.
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

      // Open the correct home after sign-in or session restoration.
      if (isSessionCheck || isAuthPage || location == '/') {
        return homePath;
      }

      // Protect each role's private area.
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
        path: '/',
        redirect: (context, state) => '/session-check',
      ),
      GoRoute(
        path: '/session-check',
        builder: (context, state) => const SessionCheckPage(),
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
          final role =
              state.uri.queryParameters['role'] == 'hotelOwner'
                  ? UserRole.hotelOwner
                  : UserRole.traveler;

          return SignUpPage(role: role);
        },
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
      return HotelDetailsPage(
      hotelId: state.pathParameters['hotelId']!,
    );
  },
),
      GoRoute(
       path: '/admin/hotels',
      builder: (context, state) => const PendingHotelsPage(),
),
GoRoute(
  path: '/admin/hotels/:hotelId',
  builder: (context, state) {
    return HotelDetailsPage(
      hotelId: state.pathParameters['hotelId']!,
    );
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
      final id = Uri.encodeComponent(
        state.pathParameters['hotelId']!,
      );
      return '/owner/hotels/$id';
    }

    return null;
  },
  builder: (context, state) {
    return AddHotelPage(
      hotel: state.extra as HotelEntity,
    );
  },
),
    ],
  );
}
    
   
