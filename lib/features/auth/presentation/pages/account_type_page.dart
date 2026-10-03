import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AccountTypePage extends StatelessWidget {
  const AccountTypePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join TALA Trip'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'How will you use TALA?',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Choose your account type to get started.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.push('/sign-up?role=traveler');
                    },
                    icon: const Icon(Icons.explore_outlined),
                    label: const Text('I am a traveler'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Discover Algeria and request hotel reservations.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () {
                      context.push('/sign-up?role=hotelOwner');
                    },
                    icon: const Icon(Icons.hotel_outlined),
                    label: const Text('I manage a hotel'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'List your hotel and manage booking requests.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextButton(
                    onPressed: () => context.go('/sign-in'),
                    child: const Text('Already have an account? Sign in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}