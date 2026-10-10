import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/user_role.dart';
import '../widgets/auth_page_layout.dart';

class AccountTypePage extends StatefulWidget {
  const AccountTypePage({super.key});

  @override
  State<AccountTypePage> createState() => _AccountTypePageState();
}

class _AccountTypePageState extends State<AccountTypePage> {
  UserRole _selectedRole = UserRole.traveler;

  @override
  Widget build(BuildContext context) {
    return AuthPageLayout(
      title: 'How will you use TALA?',
      subtitle: 'Choose your account type to get started.',
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/sign-in');
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RadioGroup<UserRole>(
            groupValue: _selectedRole,
            onChanged: (role) {
              if (role == null) return;
              setState(() => _selectedRole = role);
            },
            child: Column(
              children: [
                _roleCard(
                  role: UserRole.traveler,
                  title: 'Traveler',
                  description: 'Find hotels and request your next stay.',
                  icon: Icons.luggage_outlined,
                  accent: AppColors.primary,
                  tint: AppColors.infoSurface,
                ),
                const SizedBox(height: 16),
                _roleCard(
                  role: UserRole.hotelOwner,
                  title: 'Hotel owner',
                  description: 'List your hotels and manage booking requests.',
                  icon: Icons.apartment_outlined,
                  accent: AppColors.ownerAccent,
                  tint: AppColors.ownerSurface,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: () =>
                context.push('/sign-up?role=${_selectedRole.name}'),
            child: const Text('Continue'),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Already have an account?',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              TextButton(
                onPressed: () => context.go('/sign-in'),
                child: const Text('Sign in'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _roleCard({
    required UserRole role,
    required String title,
    required String description,
    required IconData icon,
    required Color accent,
    required Color tint,
  }) {
    final selected = role == _selectedRole;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: selected ? tint : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? accent : AppColors.subtleBorder,
          width: selected ? 1.8 : 1,
        ),
      ),
      child: RadioListTile<UserRole>(
        value: role,
        activeColor: accent,
        controlAffinity: ListTileControlAffinity.trailing,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 20,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          title,
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        secondary: CircleAvatar(
          radius: 25,
          backgroundColor: tint,
          child: Icon(icon, color: accent, size: 30),
        ),
      ),
    );
  }
}
