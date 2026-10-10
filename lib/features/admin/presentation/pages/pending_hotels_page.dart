import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:tala_trip_app/core/di/injection_container.dart';
import 'package:tala_trip_app/features/hotels/presentation/bloc/hotel_bloc.dart';
import 'package:tala_trip_app/features/hotels/presentation/bloc/hotel_event.dart';
import 'package:tala_trip_app/features/hotels/presentation/bloc/hotel_state.dart';
import 'package:tala_trip_app/features/hotels/presentation/widgets/hotel_card.dart';

class PendingHotelsPage extends StatelessWidget {
  const PendingHotelsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HotelBloc>(
      create: (_) => getIt<HotelBloc>()..add(GetPendingHotelsEvent()),
      child: const _PendingHotelsView(),
    );
  }
}

class _PendingHotelsView extends StatelessWidget {
  const _PendingHotelsView();

  void _reload(BuildContext context) {
    context.read<HotelBloc>().add(GetPendingHotelsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending hotels'),
        actions: [
          BlocBuilder<HotelBloc, HotelState>(
            builder: (context, state) {
              return IconButton(
                tooltip: 'Refresh',
                onPressed: state is HotelLoadingState
                    ? null
                    : () => _reload(context),
                icon: const Icon(Icons.refresh),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<HotelBloc, HotelState>(
        builder: (context, state) {
          if (state is HotelInitialState || state is HotelLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is HotelErrorState) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _reload(context),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is HotelsEmptyState) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No hotels are waiting for review.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (state is HotelsLoadedState) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.hotels.length,
              itemBuilder: (context, index) {
                final hotel = state.hotels[index];

                return HotelCard(
                  name: hotel.name,
                  wilaya: hotel.wilaya,
                  status: hotel.status.name,
                  onTap: () async {
                    await context.push(
                      '/admin/hotels/${Uri.encodeComponent(hotel.id)}',
                    );

                    if (!context.mounted) return;

                    _reload(context);
                  },
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
