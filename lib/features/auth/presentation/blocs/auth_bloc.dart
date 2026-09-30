import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tala_trip_app/core/errors/failures.dart';
import 'package:tala_trip_app/features/auth/domain/entities/user_entity.dart';
import 'package:tala_trip_app/features/auth/domain/usecases/auth_usecases.dart';

import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required SignUp signUp,
    required SignIn signIn,
    required SendVerificationEmail sendVerificationEmail,
    required IsEmailVerified isEmailVerified,
    required SendPasswordResetEmail sendPasswordResetEmail,
    required GetUser getUser,
  })  : _signUp = signUp,
        _signIn = signIn,
        _sendVerificationEmail = sendVerificationEmail,
        _isEmailVerified = isEmailVerified,
        _sendPasswordResetEmail = sendPasswordResetEmail,
        _getUser = getUser,
        super(AuthInitial()) {
    on<SignUpRequested>(_onSignUpRequested);
    on<SignInRequested>(_onSignInRequested);
    on<ResendVerificationEmailRequested>(
      _onResendVerificationEmailRequested,
    );
    on<CheckEmailVerificationRequested>(
      _onCheckEmailVerificationRequested,
    );
    on<PasswordResetRequested>(_onPasswordResetRequested);
    on<AuthSessionCheckRequested>(_onAuthSessionCheckRequested);
  }

  final SignUp _signUp;
  final SignIn _signIn;
  final SendVerificationEmail _sendVerificationEmail;
  final IsEmailVerified _isEmailVerified;
  final SendPasswordResetEmail _sendPasswordResetEmail;
  final GetUser _getUser;

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
    );

    await result.fold<Future<void>>(
      (failure) async {
        emit(AuthError(message: failure.message));
      },
      (user) async {
        final emailResult = await _sendVerificationEmail();

        emailResult.fold<void>(
          (failure) {
            emit(AuthVerificationRequired(
              user: user,
              message:
                  'Your account was created, but we could not send '
                  'the verification email. ${failure.message}',
            ));
          },
          (_) {
            emit(AuthVerificationRequired(
              user: user,
              message: 'We sent a verification link to ${user.email}.',
            ));
          },
        );
      },
    );
  }

  Future<void> _onSignInRequested(
    SignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await _signIn(
      email: event.email,
      password: event.password,
    );

    await result.fold<Future<void>>(
      (failure) async {
        emit(AuthError(message: failure.message));
      },
      (user) async {
        await _emitSessionForUser(user, emit);
      },
    );
  }

  Future<void> _emitSessionForUser(
    UserEntity user,
    Emitter<AuthState> emit,
  ) async {
    final result = await _isEmailVerified();

    result.fold<void>(
      (failure) {
        emit(AuthVerificationRequired(
          user: user,
          message:
              'We could not check your email verification. '
              '${failure.message}',
        ));
      },
      (verified) {
        if (verified) {
          emit(AuthAuthenticated(user: user));
        } else {
          emit(AuthVerificationRequired(user: user));
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
        emit(AuthVerificationRequired(
          user: user,
          message: failure.message,
        ));
      },
      (_) {
        emit(AuthVerificationRequired(
          user: user,
          message: 'Verification email sent to ${user.email}.',
        ));
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
        emit(AuthVerificationRequired(
          user: user,
          message: failure.message,
        ));
      },
      (verified) {
        if (verified) {
          emit(AuthAuthenticated(user: user));
        } else {
          emit(AuthVerificationRequired(
            user: user,
            message: 'Your email is not verified yet. Check your inbox.',
          ));
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
        emit(AuthError(message: failure.message));
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
          emit(AuthError(message: failure.message));
        }
      },
      (user) async {
        await _emitSessionForUser(user, emit);
      },
    );
  }
}

