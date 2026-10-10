import 'package:equatable/equatable.dart';

abstract class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object?> get props => [];
}

class OnboardingCheckRequested extends OnboardingEvent {
  const OnboardingCheckRequested();
}

class OnboardingCompletionRequested extends OnboardingEvent {
  const OnboardingCompletionRequested();
}
