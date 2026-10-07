import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tala_trip_app/core/constants/app_assets.dart';
import 'package:tala_trip_app/core/constants/app_colors.dart';
import 'package:tala_trip_app/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:tala_trip_app/features/auth/presentation/blocs/auth_event.dart';
import 'package:tala_trip_app/features/auth/presentation/blocs/auth_state.dart';

import '../bloc/onboarding_bloc.dart';
import '../bloc/onboarding_event.dart';
import '../bloc/onboarding_state.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final logoSize = 220.w.clamp(160.0, 280.0).toDouble();
    final taglineSize = 16.sp.clamp(14.0, 20.0).toDouble();

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Your splash photo, without extra gradients or filters.
          Image.asset(
            AppAssets.splash,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('SPLASH IMAGE ERROR: $error');

              return const ColoredBox(color: AppColors.primary);
            },
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          SizedBox(height: constraints.maxHeight * 0.15),

                          // The image already contains TALA TRIP.
                          Image.asset(
                            AppAssets.logo,
                            width: logoSize,
                            height: logoSize,
                            fit: BoxFit.contain,
                            semanticLabel: 'TALA Trip',
                            errorBuilder: (context, error, stackTrace) {
                              return SizedBox(
                                width: logoSize,
                                height: logoSize,
                                child: const Icon(
                                  Icons.broken_image_outlined,
                                  color: AppColors.onPrimary,
                                  size: 48,
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 12),

                          Text(
                            'Travel Algeria, Live Adventure',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  fontSize: taglineSize,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.onPrimary,
                                ),
                          ),

                          const SizedBox(height: 32),

                          BlocBuilder<OnboardingBloc, OnboardingState>(
                            builder: (context, onboardingState) {
                              if (onboardingState is OnboardingCheckFailure) {
                                return _buildRetry(
                                  context,
                                  message:
                                      'We couldn’t load your app preferences.',
                                  onRetry: () {
                                    context.read<OnboardingBloc>().add(
                                      const OnboardingCheckRequested(),
                                    );
                                  },
                                );
                              }

                              return BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, authState) {
                                  if (onboardingState is OnboardingCompleted &&
                                      authState is AuthError) {
                                    return _buildRetry(
                                      context,
                                      message: authState.message,
                                      onRetry: () {
                                        context.read<AuthBloc>().add(
                                          AuthSessionCheckRequested(),
                                        );
                                      },
                                    );
                                  }

                                  return const SizedBox.shrink();
                                },
                              );
                            },
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetry(
    BuildContext context, {
    required String message,
    required VoidCallback onRetry,
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
