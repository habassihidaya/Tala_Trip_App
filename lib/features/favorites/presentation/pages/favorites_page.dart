import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

  bool get _canReload {
    if (!mounted || _bloc.isClosed) return false;

    final authState = context.read<AuthBloc>().state;

    if (authState is! AuthAuthenticated || authState.isSigningOut) {
      return false;
    }

    return _bloc.state.hotelsStatus != FavoritesStatus.loading &&
        _bloc.state.updatingHotelIds.isEmpty;
  }

  void _reload() {
    if (!_canReload) return;

    _bloc.add(const FavoriteHotelsRequested());
  }

  Future<void> _refreshFavorites() async {
    if (!_canReload) return;

    // Subscribe before sending the request.
    // Wait for hotel loading, not just favorite-ID loading.
    final refreshFinished = _bloc.stream
        .skipWhile((state) => state.hotelsStatus != FavoritesStatus.loading)
        .where(
          (state) =>
              state.hotelsStatus == FavoritesStatus.success ||
              state.hotelsStatus == FavoritesStatus.failure,
        )
        .take(1)
        .drain<void>();

    _bloc.add(const FavoriteHotelsRequested());

    await refreshFinished;
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final sessionAvailable =
        authState is AuthAuthenticated && !authState.isSigningOut;

    return BlocBuilder<FavoritesBloc, FavoritesState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Favorites'),
            automaticallyImplyLeading: false,
          ),
          body: SafeArea(
            child: RefreshIndicator(
              color: Theme.of(context).colorScheme.primary,
              onRefresh: _refreshFavorites,
              child: CustomScrollView(
                key: const PageStorageKey<String>('favorite_hotels'),
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [_buildContent(state, sessionAvailable)],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(FavoritesState state, bool sessionAvailable) {
    if (state.hotelsStatus == FavoritesStatus.initial ||
        state.hotelsStatus == FavoritesStatus.loading) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.hotelsStatus == FavoritesStatus.failure) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _FavoritesMessage(
          icon: Icons.error_outline,
          title: 'Could not load favorites',
          message: state.hotelsError ?? 'Please try again.',
          action: FilledButton(
            onPressed: sessionAvailable && state.updatingHotelIds.isEmpty
                ? _refreshFavorites
                : null,
            child: const Text('Retry'),
          ),
        ),
      );
    }

    if (state.isEmpty) {
      final hasSavedIds = state.favoriteIds.isNotEmpty;

      return SliverFillRemaining(
        hasScrollBody: false,
        child: _FavoritesMessage(
          icon: Icons.favorite_border,
          title: hasSavedIds
              ? 'Your saved hotels are currently unavailable'
              : 'No favorite hotels yet',
          message: hasSavedIds
              ? 'Your selection is saved. '
                    'Pull down to refresh or discover other hotels.'
              : 'Tap the heart on a hotel to save it here.',
          action: FilledButton(
            onPressed: sessionAvailable ? () => context.go('/traveler') : null,
            child: const Text('Explore hotels'),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.all(16.r),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final hotel = state.hotels[index];

          return TravelerHotelCard(
            key: ValueKey(hotel.id),
            hotel: hotel,
            onTap: () async {
              await context.push(
                '/traveler/hotels/${Uri.encodeComponent(hotel.id)}',
              );

              if (!mounted) return;

              _reload();
            },
          );
        }, childCount: state.hotels.length),
      ),
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
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56.r, color: theme.colorScheme.primary),
            SizedBox(height: 16.h),
            Text(
              title,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(message, textAlign: TextAlign.center),
            SizedBox(height: 24.h),
            action,
          ],
        ),
      ),
    );
  }
}
