import '../../../auth/domain/entities/user_entity.dart';

abstract class ProfileState {
  const ProfileState();
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoadFailure extends ProfileState {
  final String message;

  const ProfileLoadFailure({required this.message});
}

class ProfileLoaded extends ProfileState {
  final UserEntity user;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  const ProfileLoaded({
    required this.user,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
  });
}
