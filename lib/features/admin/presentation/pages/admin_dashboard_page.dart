import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/blocs/auth_bloc.dart';
import '../../../auth/presentation/blocs/auth_event.dart';
import '../../../auth/presentation/blocs/auth_state.dart';
import 'package:go_router/go_router.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final authenticated =
            state is AuthAuthenticated ? state : null;

        final signingOut = authenticated?.isSigningOut ?? false;
        final error = authenticated?.signOutError;

        return Scaffold(
          appBar: AppBar(
            title: const Text('TALA Admin'),
            automaticallyImplyLeading: false,
            actions: [
              TextButton(
                onPressed: authenticated == null || signingOut
                    ? null
                    : () {
                        context.read<AuthBloc>().add(
                          SignOutRequested(),
                        );
                      },
                child: Text(
                  signingOut ? 'Signing out...' : 'Sign out',
                ),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Admin dashboard',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Review hotel-owner applications and '
                  'hotels submitted for publication.',
                ),
                 const SizedBox(height: 24),
FilledButton.icon(
  onPressed: authenticated == null || signingOut
      ? null
      : () {
          context.push('/admin/hotels');
        },
  icon: const Icon(Icons.fact_check_outlined),
  label: const Text('Review pending hotels'),
),
                if (signingOut) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(),
                ],
                if (error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    error,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}