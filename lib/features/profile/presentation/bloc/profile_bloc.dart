import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/usecases/profile_usecases.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetProfile _getProfile;
  final UpdateProfileName _updateProfileName;
  final UpdateProfilePhoto _updateProfilePhoto;

  ProfileBloc({
    required this._getProfile,
    required this._updateProfileName,
    required this._updateProfilePhoto,
  }) : super(const ProfileInitial()) {
    on<ProfileEvent>(
      _onEvent,
      transformer: (events, mapper) => events.asyncExpand(mapper),
    );
  }

  Future<void> _onEvent(ProfileEvent event, Emitter<ProfileState> emit) async {
    if (event is ProfileRequested) {
      await _loadProfile(emit);
    } else if (event is ProfileNameUpdateRequested) {
      await _saveProfile(
        emit,
        action: () => _updateProfileName(username: event.username),
        successMessage: 'Your name was updated.',
      );
    } else if (event is ProfilePhotoUpdateRequested) {
      await _saveProfile(
        emit,
        action: () => _updateProfilePhoto(filePath: event.filePath),
        successMessage: 'Your profile photo was updated.',
      );
    }
  }

  Future<void> _loadProfile(Emitter<ProfileState> emit) async {
    emit(const ProfileLoading());

    final result = await _getProfile();

    result.fold<void>(
      (failure) {
        emit(ProfileLoadFailure(message: failure.message));
      },
      (user) {
        emit(ProfileLoaded(user: user));
      },
    );
  }

  Future<void> _saveProfile(
    Emitter<ProfileState> emit, {
    required Future<Either<Failure, UserEntity>> Function() action,
    required String successMessage,
  }) async {
    final currentState = state;

    if (currentState is! ProfileLoaded || currentState.isSaving) {
      return;
    }

    emit(ProfileLoaded(user: currentState.user, isSaving: true));

    final result = await action();

    result.fold<void>(
      (failure) {
        emit(
          ProfileLoaded(user: currentState.user, errorMessage: failure.message),
        );
      },
      (user) {
        emit(ProfileLoaded(user: user, successMessage: successMessage));
      },
    );
  }
}
