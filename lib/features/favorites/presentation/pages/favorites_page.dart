import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/blocs/auth_bloc.dart';
import '../../../auth/presentation/blocs/auth_state.dart';
import '../bloc/favorites_bloc.dart';
import '../bloc/favorites_event.dart';
import '../bloc/favorites_state.dart';
import '../widgets/traveler_hotel_card.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  late final FavoritesBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = context.read<FavoritesBloc>();

    if (_bloc.state.hotelsStatus == FavoritesStatus.initial) {
      _bloc.add(const FavoriteHotelsRequested());
    }
  }

  void _reload() {
    if (!mounted || _bloc.isClosed) {
      return;
    }

    final authState = context.read<AuthBloc>().state;

    if (authState is! AuthAuthenticated || authState.isSigningOut) {
      return;
    }

    if (_bloc.state.hotelsStatus == FavoritesStatus.loading ||
        _bloc.state.updatingHotelIds.isNotEmpty) {
      return;
    }

    _bloc.add(const FavoriteHotelsRequested());
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final sessionAvailable =
        authState is AuthAuthenticated && !authState.isSigningOut;

    return BlocBuilder<FavoritesBloc, FavoritesState>(
      builder: (context, state) {
        final busy =
            state.hotelsStatus == FavoritesStatus.loading ||
            state.updatingHotelIds.isNotEmpty;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Favorites'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                tooltip: 'Refresh favorites',
                onPressed: sessionAvailable && !busy ? _reload : null,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: SafeArea(child: _buildContent(state, sessionAvailable)),
        );
      },
    );
  }

  Widget _buildContent(FavoritesState state, bool sessionAvailable) {
    if (state.hotelsStatus == FavoritesStatus.initial ||
        state.hotelsStatus == FavoritesStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.hotelsStatus == FavoritesStatus.failure) {
      return _FavoritesMessage(
        icon: Icons.error_outline,
        title: 'Could not load favorites',
        message: state.hotelsError ?? 'Please try again.',
        action: FilledButton(
          onPressed: sessionAvailable ? _reload : null,
          child: const Text('Retry'),
        ),
      );
    }

    if (state.isEmpty) {
      final hasSavedIds = state.favoriteIds.isNotEmpty;

      return _FavoritesMessage(
        icon: Icons.favorite_border,
        title: hasSavedIds
            ? 'Your saved hotels are currently unavailable'
            : 'No favorite hotels yet',
        message: hasSavedIds
            ? 'Your selection is saved. Refresh later or discover other hotels.'
            : 'Tap the heart on a hotel to save it here.',
        action: FilledButton(
          onPressed: sessionAvailable ? () => context.go('/traveler') : null,
          child: const Text('Explore hotels'),
        ),
      );
    }

    return ListView.builder(
      key: const PageStorageKey<String>('favorite_hotels'),
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

            if (mounted) {
              _reload();
            }
          },
        );
      },
    );
  }
}

class _FavoritesMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget action;

  const _FavoritesMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            action,
          ],
        ),
      ),
    );
  }
}
