import 'package:equatable/equatable.dart';

abstract class OnboardingState extends Equatable {
  const OnboardingState();

  @override
  List<Object?> get props => [];
}

class OnboardingInitial extends OnboardingState {
  const OnboardingInitial();
}

class OnboardingChecking extends OnboardingState {
  const OnboardingChecking();
}

class OnboardingRequired extends OnboardingState {
  const OnboardingRequired();
}

class OnboardingSaving extends OnboardingState {
  const OnboardingSaving();
}

class OnboardingCompleted extends OnboardingState {
  const OnboardingCompleted();
}

class OnboardingCheckFailure extends OnboardingState {
  final String message;

  const OnboardingCheckFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class OnboardingSaveFailure extends OnboardingState {
  final String message;

  const OnboardingSaveFailure(this.message);

  @override
  List<Object?> get props => [message];
}
