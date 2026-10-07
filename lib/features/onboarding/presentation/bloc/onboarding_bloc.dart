import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tala_trip_app/features/onboarding/domain/usecases/onboarding_usecases.dart';

import 'onboarding_event.dart';
import 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final CheckOnboardingCompleted _checkOnboardingCompleted;
  final CompleteOnboarding _completeOnboarding;

    OnboardingBloc(
    this._checkOnboardingCompleted,
    this._completeOnboarding,
  ) : super(const OnboardingInitial()) {
    on<OnboardingCheckRequested>(_onCheckRequested);
    on<OnboardingCompletionRequested>(_onCompletionRequested);
  }

  Future<void> _onCheckRequested(
    OnboardingCheckRequested event,
    Emitter<OnboardingState> emit,
  ) async {
    // Allow the initial check or a retry after a failed check.
    if (state is! OnboardingInitial &&
        state is! OnboardingCheckFailure) {
      return;
    }

    emit(const OnboardingChecking());

    final result = await _checkOnboardingCompleted();

    result.fold<void>(
      (failure) => emit(OnboardingCheckFailure(failure.message)),
      (completed) {
        emit(
          completed
              ? const OnboardingCompleted()
              : const OnboardingRequired(),
        );
      },
    );
  }

  Future<void> _onCompletionRequested(
    OnboardingCompletionRequested event,
    Emitter<OnboardingState> emit,
  ) async {
    // Allow completion or a retry after saving failed.
    if (state is! OnboardingRequired &&
        state is! OnboardingSaveFailure) {
      return;
    }

    emit(const OnboardingSaving());

    final result = await _completeOnboarding();

    result.fold<void>(
      (failure) => emit(OnboardingSaveFailure(failure.message)),
      (_) => emit(const OnboardingCompleted()),
    );
  }
}