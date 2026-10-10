import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/blocs/auth_bloc.dart';
import '../../../auth/presentation/blocs/auth_state.dart';
import '../../../hotels/domain/entities/hotel_entity.dart';
import '../bloc/favorites_bloc.dart';
import '../bloc/favorites_event.dart';
import '../bloc/favorites_state.dart';

class TravelerHotelCard extends StatelessWidget {
  final HotelEntity hotel;
  final VoidCallback onTap;

  const TravelerHotelCard({
    super.key,
    required this.hotel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onTap,
            child: hotel.images.isEmpty
                ? const _PhotoPlaceholder()
                : Image.network(
                    hotel.images.first,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) {
                        return child;
                      }

                      return const SizedBox(
                        height: 180,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const _PhotoPlaceholder();
                    },
                  ),
          ),
          ListTile(
            onTap: onTap,
            title: Text(hotel.name),
            subtitle: Text(hotel.wilaya),
            trailing: _FavoriteButton(hotel: hotel),
          ),
        ],
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(child: Icon(Icons.hotel_outlined, size: 48)),
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  final HotelEntity hotel;

  const _FavoriteButton({required this.hotel});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final canEdit = authState is AuthAuthenticated && !authState.isSigningOut;

    return BlocBuilder<FavoritesBloc, FavoritesState>(
      builder: (context, state) {
        final bloc = context.read<FavoritesBloc>();

        if (state.idsStatus == FavoritesStatus.failure) {
          return IconButton(
            tooltip: 'Retry loading favorites',
            onPressed: canEdit
                ? () => bloc.add(const FavoritesStarted())
                : null,
            icon: const Icon(Icons.refresh),
          );
        }

        final isFavorite = state.isFavorite(hotel.id);
        final isUpdating = state.isUpdating(hotel.id);

        final isBusy =
            state.idsStatus != FavoritesStatus.success ||
            state.hotelsStatus == FavoritesStatus.loading ||
            state.updatingHotelIds.isNotEmpty;

        return IconButton(
          tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
          onPressed: canEdit && !isBusy
              ? () => bloc.add(FavoriteToggled(hotel: hotel))
              : null,
          icon: isUpdating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
        );
      },
    );
  }
}
