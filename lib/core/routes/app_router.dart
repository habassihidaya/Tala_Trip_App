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
    ],
  );
}
    
   
