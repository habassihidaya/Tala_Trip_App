import 'package:go_router/go_router.dart';

import 'package:tala_trip_app/features/admin/presentation/pages/admin_dashboard_page.dart';
import 'package:tala_trip_app/features/auth/domain/entities/user_role.dart';
import 'package:tala_trip_app/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:tala_trip_app/features/auth/presentation/blocs/auth_state.dart';
import 'package:tala_trip_app/features/auth/presentation/pages/session_check_page.dart';
import 'package:tala_trip_app/features/auth/presentation/pages/sign_in_page.dart';
import 'package:tala_trip_app/features/auth/presentation/pages/sign_up_page.dart';

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

      // At startup, wait for a session result.
      // Errors stay on the session-check screen with Retry.
      if (!startupResolved) {
        if (!hasSessionResult) {
          return isSessionCheck ? null : '/session-check';
        }

        startupResolved = true;
      }

      final isAdmin = authState is AuthAuthenticated &&
          authState.user.role == UserRole.admin;

      // Leave the startup screen once the session is resolved.
      if (isSessionCheck) {
        if (!hasSessionResult) return null;

        return isAdmin ? '/admin' : '/sign-in';
      }

      final isAdminRoute =
          location == '/admin' || location.startsWith('/admin/');

      // Protect admin pages.
      if (isAdminRoute && !isAdmin) {
        return '/sign-in';
      }

      // Send authenticated admins to their dashboard.
      if (isAdmin &&
          (location == '/sign-in' ||
              location == '/sign-up' ||
              location == '/')) {
        return '/admin';
      }

      if (location == '/') {
        return '/sign-in';
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
        path: '/sign-up',
        builder: (context, state) => const SignUpPage(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardPage(),
      ),
    ],
  );
}
    
   
