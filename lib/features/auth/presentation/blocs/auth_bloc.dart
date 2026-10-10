import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:tala_trip_app/core/errors/failures.dart';
import 'package:tala_trip_app/features/auth/domain/entities/user_entity.dart';
import 'package:tala_trip_app/features/auth/domain/usecases/auth_usecases.dart';

import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required this._signUp,
    required this._signIn,
    required this._watchAuthState,
    required this._sendVerificationEmail,
    required this._isEmailVerified,
    required this._sendPasswordResetEmail,
    required this._getUser,
    required this._signOut,
  }) : super(AuthInitial()) {
    on<AuthEvent>(
      _onAuthEvent,
      transformer: (events, mapper) => events.asyncExpand(mapper),
    );
    _authSubscription = _watchAuthState().listen((result) {
      if (!isClosed) {
        add(AuthSessionChanged(result));
      }
    });
  }

  final SignUp _signUp;
  final SignIn _signIn;
  final SendVerificationEmail _sendVerificationEmail;
  final IsEmailVerified _isEmailVerified;
  final SendPasswordResetEmail _sendPasswordResetEmail;
  final GetUser _getUser;
  final SignOut _signOut;
  final WatchAuthState _watchAuthState;
  Future<void> _onSignUpRequested(
    SignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await _signUp(
      username: event.username,
      email: event.email,
      password: event.password,
      mobileNumber: event.mobileNumber,
      role: event.role,
    );

    await result.fold<Future<void>>(
      (failure) async {
        _emitFailure(failure, emit);
      },
      (user) async {
        final emailResult = await _sendVerificationEmail();

        await emailResult.fold<Future<void>>(
          (failure) async {
            emit(
              AuthVerificationRequired(
                user: user,
                message:
                    'Your account was created, but we could not send '
                    'the verification email. ${failure.message}',
              ),
            );
          },
          (_) async {
            await _emitSessionForUser(
              user,
              emit,
              verificationMessage:
                  'We sent a verification link to ${user.email}.',
            );
          },
        );
      },
    );
  }

  void _emitFailure(Failure failure, Emitter<AuthState> emit) {
    if (failure is IncompleteProfileFailure) {
      emit(AuthProfileRequired(message: failure.message));
    } else {
      emit(AuthError(message: failure.message));
    }
  }

  Future<void> _onSignInRequested(
    SignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await _signIn(email: event.email, password: event.password);

    await result.fold<Future<void>>(
      (failure) async {
        _emitFailure(failure, emit);
      },
      (user) async {
        await _emitSessionForUser(user, emit);
      },
    );
  }

  Future<void> _emitSessionForUser(
    UserEntity user,
    Emitter<AuthState> emit, {
    String? verificationMessage,
  }) async {
    final result = await _isEmailVerified();

    result.fold<void>(
      (failure) {
        emit(
          AuthVerificationRequired(
            user: user,
            message:
                'We could not check your email verification. '
                '${failure.message}',
          ),
        );
      },
      (verified) {
        if (verified) {
          emit(AuthAuthenticated(user: user));
        } else {
          emit(
            AuthVerificationRequired(user: user, message: verificationMessage),
          );
        }
      },
    );
  }

  Future<void> _onResendVerificationEmailRequested(
    ResendVerificationEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AuthVerificationRequired) return;

    final user = currentState.user;
    emit(AuthLoading());

    final result = await _sendVerificationEmail();

    result.fold<void>(
      (failure) {
        emit(AuthVerificationRequired(user: user, message: failure.message));
      },
      (_) {
        emit(
          AuthVerificationRequired(
            user: user,
            message: 'Verification email sent to ${user.email}.',
          ),
        );
      },
    );
  }

  Future<void> _onCheckEmailVerificationRequested(
    CheckEmailVerificationRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AuthVerificationRequired) return;

    final user = currentState.user;
    emit(AuthLoading());

    final result = await _isEmailVerified();

    result.fold<void>(
      (failure) {
        emit(AuthVerificationRequired(user: user, message: failure.message));
      },
      (verified) {
        if (verified) {
          emit(AuthAuthenticated(user: user));
        } else {
          emit(
            AuthVerificationRequired(
              user: user,
              message: 'Your email is not verified yet. Check your inbox.',
            ),
          );
        }
      },
    );
  }

  Future<void> _onPasswordResetRequested(
    PasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await _sendPasswordResetEmail(event.email);

    result.fold<void>(
      (failure) {
        _emitFailure(failure, emit);
      },
      (_) {
        emit(AuthPasswordResetEmailSent());
      },
    );
  }

  Future<void> _onAuthSessionCheckRequested(
    AuthSessionCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await _getUser();

    await result.fold<Future<void>>(
      (failure) async {
        if (failure is UnauthenticatedFailure) {
          emit(AuthUnauthenticated());
        } else {
          _emitFailure(failure, emit);
        }
      },
      (user) async {
        await _emitSessionForUser(user, emit);
      },
    );
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;

    if (currentState is! AuthAuthenticated) return;
    if (currentState.isSigningOut) return;

    final user = currentState.user;

    emit(AuthAuthenticated(user: user, isSigningOut: true));

    final result = await _signOut();

    result.fold<void>(
      (failure) {
        emit(AuthAuthenticated(user: user, signOutError: failure.message));
      },
      (_) {
        emit(AuthUnauthenticated());
      },
    );
  }

  Future<void> _onAuthEvent(AuthEvent event, Emitter<AuthState> emit) async {
    if (event is SignUpRequested) {
      await _onSignUpRequested(event, emit);
    } else if (event is SignInRequested) {
      await _onSignInRequested(event, emit);
    } else if (event is ResendVerificationEmailRequested) {
      await _onResendVerificationEmailRequested(event, emit);
    } else if (event is CheckEmailVerificationRequested) {
      await _onCheckEmailVerificationRequested(event, emit);
    } else if (event is PasswordResetRequested) {
      await _onPasswordResetRequested(event, emit);
    } else if (event is AuthSessionCheckRequested) {
      await _onAuthSessionCheckRequested(event, emit);
    } else if (event is SignOutRequested) {
      await _onSignOutRequested(event, emit);
    } else if (event is AuthSessionChanged) {
      await _onAuthSessionChanged(event, emit);
    } else if (event is AuthUserProfileUpdated) {
      _onAuthUserProfileUpdated(event, emit);
    }
  }

  Future<void> _onAuthSessionChanged(
    AuthSessionChanged event,
    Emitter<AuthState> emit,
  ) async {
    await event.result.fold<Future<void>>(
      (failure) async {
        _emitFailure(failure, emit);
      },
      (userId) async {
        if (userId == null) {
          if (state is! AuthUnauthenticated) {
            emit(AuthUnauthenticated());
          }
          return;
        }

        final currentState = state;

        // Our sign-in handler already loaded this account.
        if (currentState is AuthAuthenticated &&
            currentState.user.id == userId) {
          return;
        }

        // Preserve the verification screen and its message.
        if (currentState is AuthVerificationRequired &&
            currentState.user.id == userId) {
          return;
        }

        emit(AuthLoading());

        final result = await _getUser();

        await result.fold<Future<void>>(
          (failure) async {
            _emitFailure(failure, emit);
          },
          (user) async {
            // Do not use another account's profile for this event.
            if (user.id != userId) return;

            await _emitSessionForUser(user, emit);
          },
        );
      },
    );
  }

  StreamSubscription<Either<Failure, String?>>? _authSubscription;
  @override
  Future<void> close() async {
    await _authSubscription?.cancel();
    await super.close();
  }

  void _onAuthUserProfileUpdated(
    AuthUserProfileUpdated event,
    Emitter<AuthState> emit,
  ) {
    final currentState = state;

    if (currentState is! AuthAuthenticated ||
        currentState.isSigningOut ||
        currentState.user.id != event.user.id) {
      return;
    }

    final currentUser = currentState.user;

    final updatedUser = UserEntity(
      id: currentUser.id,
      username: event.user.username,
      email: currentUser.email,
      mobileNumber: currentUser.mobileNumber,
      role: currentUser.role,
      profileImageUrl: event.user.profileImageUrl,
      lastUsernameChangeAt: event.user.lastUsernameChangeAt,
    );

    emit(
      AuthAuthenticated(
        user: updatedUser,
        signOutError: currentState.signOutError,
      ),
    );
  }
}
