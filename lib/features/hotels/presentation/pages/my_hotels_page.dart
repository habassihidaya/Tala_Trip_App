import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tala_trip_app/core/di/injection_container.dart';
import 'package:tala_trip_app/features/hotels/presentation/bloc/hotel_bloc.dart';
import 'package:tala_trip_app/features/hotels/presentation/bloc/hotel_event.dart';
import 'package:tala_trip_app/features/hotels/presentation/bloc/hotel_state.dart';
import 'package:tala_trip_app/features/hotels/presentation/widgets/hotel_card.dart';
import 'package:go_router/go_router.dart';

class MyHotelsPage extends StatelessWidget {
  const MyHotelsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HotelBloc>(
      create: (_) => getIt<HotelBloc>()..add(GetMyHotelsEvent()),
      child: const _MyHotelsView(),
    );
  }
}

class _MyHotelsView extends StatelessWidget {
  const _MyHotelsView();

  void _reload(BuildContext context) {
    context.read<HotelBloc>().add(GetMyHotelsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await context.push<bool>('/owner/hotels/add');

          if (!context.mounted) return;

          if (created == true) {
            _reload(context);

            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Hotel draft saved.')));
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add hotel'),
      ),
      appBar: AppBar(
        title: const Text('My hotels'),
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
                  'You haven’t added a hotel yet.',
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
                    final submitted = await context.push<bool>(
                      '/owner/hotels/${Uri.encodeComponent(hotel.id)}',
                    );

                    if (!context.mounted) return;

                    _reload(context);

                    if (submitted == true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Hotel submitted for review.'),
                        ),
                      );
                    }
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
