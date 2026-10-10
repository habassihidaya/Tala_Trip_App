import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/blocs/auth_bloc.dart';
import '../../../auth/presentation/blocs/auth_state.dart';
import '../bloc/favorites_bloc.dart';
import '../bloc/favorites_event.dart';
import '../bloc/favorites_state.dart';

class TravelerFavoritesScope extends StatelessWidget {
  final AuthBloc authBloc;
  final Widget child;

  const TravelerFavoritesScope({
    super.key,
    required this.authBloc,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      bloc: authBloc,
      builder: (context, state) {
        if (state is! AuthAuthenticated ||
            state.user.role != UserRole.traveler) {
          return const SizedBox.shrink();
        }

        return BlocProvider<FavoritesBloc>(
          key: ValueKey(state.user.id),
          create: (_) => getIt<FavoritesBloc>()..add(const FavoritesStarted()),
          child: BlocListener<FavoritesBloc, FavoritesState>(
            listenWhen: (previous, current) =>
                (current.actionError != null &&
                    current.actionError != previous.actionError) ||
                (current.idsError != null &&
                    current.idsError != previous.idsError),
            listener: (context, state) {
              final message = state.actionError ?? state.idsError;

              if (message == null) {
                return;
              }

              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(message)));
            },
            child: child,
          ),
        );
      },
    );
  }
}
