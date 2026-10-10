import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tala_trip_app/core/constants/app_assets.dart';
import 'package:tala_trip_app/core/constants/app_colors.dart';

import '../bloc/onboarding_bloc.dart';
import '../bloc/onboarding_event.dart';
import '../bloc/onboarding_state.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageController = PageController();
  int _currentPage = 0;
  bool _isMoving = false;

  static const _slides = [
    (
      image: AppAssets.onboardingDiscover,
      title: 'Explore\nAuthentic Algeria',
      description: 'From Mediterranean coastlines to mountains and deserts.',
    ),
    (
      image: AppAssets.onboardingStay,
      title: 'Find Your\nPerfect Stay',
      description: 'Explore hotels and choose a room that fits your budget.',
    ),
    (
      image: AppAssets.onboardingBooking,
      title: 'Your Next Trip\nStarts Here',
      description:
          'Request your stay. The hotel contacts you to confirm. '
          'Pay on arrival.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    if (_isMoving) return;

    if (_currentPage == _slides.length - 1) {
      context.read<OnboardingBloc>().add(const OnboardingCompletionRequested());
      return;
    }

    setState(() => _isMoving = true);

    try {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } finally {
      if (mounted) {
        setState(() => _isMoving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Limit scaling so tablets still have comfortable spacing.
    final horizontalPadding = 28.w.clamp(20.0, 40.0).toDouble();
    final titleSize = 28.sp.clamp(24.0, 34.0).toDouble();
    final bodySize = 16.sp.clamp(14.0, 20.0).toDouble();
    final dotSize = 8.r.clamp(7.0, 10.0).toDouble();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: BlocBuilder<OnboardingBloc, OnboardingState>(
        builder: (context, state) {
          final isSaving = state is OnboardingSaving;
          final canContinue =
              state is OnboardingRequired || state is OnboardingSaveFailure;
          final isLastPage = _currentPage == _slides.length - 1;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final imageHeight = (constraints.maxHeight * 0.74)
                            .clamp(160.0, 620.0)
                            .toDouble();

                        return PageView.builder(
                          controller: _pageController,
                          itemCount: _slides.length,
                          physics: isSaving || _isMoving
                              ? const NeverScrollableScrollPhysics()
                              : const PageScrollPhysics(),
                          onPageChanged: (index) {
                            setState(() => _currentPage = index);
                          },
                          itemBuilder: (context, index) {
                            final slide = _slides[index];

                            // Allows vertical scrolling on short screens
                            // or when the user enables large text.
                            return SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: imageHeight,
                                    width: double.infinity,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.asset(
                                          slide.image,
                                          fit: BoxFit.cover,
                                          excludeFromSemantics: true,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return const ColoredBox(
                                                  color: AppColors.primaryLight,
                                                  child: Center(
                                                    child: Icon(
                                                      Icons.landscape_outlined,
                                                      size: 64,
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                );
                                              },
                                        ),

                                        // Fade the photo into the white page.
                                        const Positioned(
                                          left: 0,
                                          right: 0,
                                          bottom: 0,
                                          height: 120,
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Color(0x00FFFFFF),
                                                  AppColors.surface,
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // The photo extends to the top edge.
                                  // Text stays clear of side cutouts.
                                  SafeArea(
                                    top: false,
                                    bottom: false,
                                    child: Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        horizontalPadding,
                                        0,
                                        horizontalPadding,
                                        20,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            slide.title,
                                            style: textTheme.headlineMedium
                                                ?.copyWith(
                                                  fontSize: titleSize,
                                                  color: AppColors.textPrimary,
                                                ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            slide.description,
                                            style: textTheme.bodyLarge
                                                ?.copyWith(
                                                  fontSize: bodySize,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // Keep controls above the system navigation area.
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        16,
                        horizontalPadding,
                        20,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Semantics(
                            label:
                                'Page ${_currentPage + 1} of ${_slides.length}',
                            liveRegion: true,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                _slides.length,
                                (index) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  height: dotSize,
                                  width: dotSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: index == _currentPage
                                        ? AppColors.primary
                                        : AppColors.border,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (state is OnboardingSaveFailure) ...[
                            const SizedBox(height: 12),
                            Text(
                              state.message,
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: canContinue && !_isMoving
                                  ? _onContinue
                                  : null,
                              style: FilledButton.styleFrom(
                                backgroundColor: isLastPage
                                    ? AppColors.accentAction
                                    : AppColors.primary,
                                shape: const StadiumBorder(),
                              ),
                              child: isSaving
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primary,
                                        semanticsLabel: 'Saving',
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            isLastPage ? 'Get started' : 'Next',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        if (!isLastPage) ...[
                                          const SizedBox(width: 10),
                                          const Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 20,
                                          ),
                                        ],
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
