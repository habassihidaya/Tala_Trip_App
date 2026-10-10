import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:tala_trip_app/core/di/injection_container.dart';
import 'package:tala_trip_app/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:tala_trip_app/features/auth/presentation/blocs/auth_event.dart';
import 'package:tala_trip_app/features/auth/presentation/blocs/auth_state.dart';
import 'package:tala_trip_app/features/favorites/presentation/widgets/traveler_hotel_card.dart';
import 'package:tala_trip_app/features/hotels/presentation/bloc/hotel_bloc.dart';
import 'package:tala_trip_app/features/hotels/presentation/bloc/hotel_event.dart';
import 'package:tala_trip_app/features/hotels/presentation/bloc/hotel_state.dart';

class TravelerHomePage extends StatelessWidget {
  const TravelerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TALA Trip'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'My bookings',
            onPressed: () => context.go('/traveler/bookings'),
            icon: const Icon(Icons.calendar_month_outlined),
          ),
          BlocConsumer<AuthBloc, AuthState>(
            listenWhen: (previous, current) =>
                current is AuthAuthenticated &&
                current.signOutError != null &&
                (previous is! AuthAuthenticated ||
                    previous.signOutError != current.signOutError),
            listener: (context, state) {
              if (state is AuthAuthenticated && state.signOutError != null) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.signOutError!)));
              }
            },
            builder: (context, state) {
              final signingOut =
                  state is AuthAuthenticated && state.isSigningOut;

              final canSignOut =
                  state is AuthAuthenticated && !state.isSigningOut;

              return IconButton(
                tooltip: 'Sign out',
                onPressed: canSignOut
                    ? () {
                        context.read<AuthBloc>().add(SignOutRequested());
                      }
                    : null,
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
      body: SafeArea(
        child: BlocProvider<HotelBloc>(
          create: (_) => getIt<HotelBloc>()..add(GetApprovedHotelsEvent()),
          child: const _ApprovedHotels(),
        ),
      ),
    );
  }
}

class _ApprovedHotels extends StatelessWidget {
  const _ApprovedHotels();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HotelBloc, HotelState>(
      builder: (context, state) {
        void reload() {
          context.read<HotelBloc>().add(GetApprovedHotelsEvent());
        }

        if (state is HotelInitialState || state is HotelLoadingState) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is HotelErrorState || state is HotelsEmptyState) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    state is HotelErrorState
                        ? state.message
                        : 'No approved hotels yet. Check back soon.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: reload,
                    child: Text(state is HotelErrorState ? 'Retry' : 'Refresh'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is! HotelsLoadedState) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            ListTile(
              title: const Text('Discover hotels in Algeria'),
              trailing: IconButton(
                tooltip: 'Refresh',
                onPressed: reload,
                icon: const Icon(Icons.refresh),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.hotels.length,
                itemBuilder: (context, index) {
                  final hotel = state.hotels[index];

                  return TravelerHotelCard(
                    key: ValueKey(hotel.id),
                    hotel: hotel,
                    onTap: () async {
                      await context.push(
                        '/traveler/hotels/${Uri.encodeComponent(hotel.id)}',
                      );

                      if (context.mounted) {
                        reload();
                      }
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
