import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tala_trip_app/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:tala_trip_app/features/auth/presentation/blocs/auth_event.dart';
import 'package:tala_trip_app/features/auth/presentation/blocs/auth_state.dart';
import 'package:go_router/go_router.dart';

class HotelOwnerDashboardPage extends StatelessWidget {
  const HotelOwnerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: const Text('TALA — Owner dashboard'),
  automaticallyImplyLeading: false,
  actions: [
    BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          current is AuthAuthenticated &&
          current.signOutError != null &&
          (previous is! AuthAuthenticated ||
              previous.signOutError != current.signOutError),
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.signOutError!),
            ),
          );
        }
      },
      builder: (context, state) {
        final signingOut =
            state is AuthAuthenticated && state.isSigningOut;

        return IconButton(
          tooltip: 'Sign out',
          onPressed: signingOut
              ? null
              : () {
                  context.read<AuthBloc>().add(SignOutRequested());
                },
          icon: signingOut
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.logout),
        );
      },
    ),
  ],
),
     body: Center(
  child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.hotel_outlined,
          size: 64,
        ),
        const SizedBox(height: 16),
        const Text(
          'Welcome, hotel owner!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Manage your hotels and booking requests.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => context.push('/owner/hotels'),
          icon: const Icon(Icons.hotel),
          label: const Text('My hotels'),
        ),
        const SizedBox(height: 12),

        ElevatedButton.icon(
          onPressed: () => context.push('/owner/bookings'),
          icon: const Icon(Icons.calendar_month_outlined),
          label: const Text('Booking requests'),
      ),
      ],
    ),
  ),
),
    );
  }
}