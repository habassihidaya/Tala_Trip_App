import 'package:flutter_bloc/flutter_bloc.dart';
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
  })  : _signUp = signUp,
        _signIn = signIn,
        _sendVerificationEmail = sendVerificationEmail,
        _isEmailVerified = isEmailVerified,
        super(AuthInitial()) {
    on<SignUpRequested>(_onSignUpRequested);
    on<SignInRequested>(_onSignInRequested);
    on<ResendVerificationEmailRequested>(_onResendVerificationEmailRequested);
    on<CheckEmailVerificationRequested>(_onCheckEmailVerificationRequested);
  }

  final SignUp _signUp;
  final SignIn _signIn;
  final SendVerificationEmail _sendVerificationEmail;
  final IsEmailVerified _isEmailVerified;

  Future<void> _onSignUpRequested(
    SignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final user = await _signUp(
        username: event.username,
        email: event.email,
        password: event.password,
        mobileNumber: event.mobileNumber,
      );

      try {
        await _sendVerificationEmail();
        emit(AuthVerificationRequired(
          user: user,
          message: 'We sent a verification link to ${user.email}.',
        ));
      } catch (_) {
        // The account and profile were created, even if sending the email failed.
        emit(AuthVerificationRequired(
          user: user,
          message: 'We could not send the email. Tap Resend email.',
        ));
      }
    } catch (error) {
      emit(AuthError(message: error.toString()));
    }
  }

  Future<void> _onSignInRequested(
    SignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final user = await _signIn(
        email: event.email,
        password: event.password,
      );

      if (await _isEmailVerified()) {
        emit(AuthAuthenticated(user: user));
      } else {
        emit(AuthVerificationRequired(user: user));
      }
    } catch (error) {
      emit(AuthError(message: error.toString()));
    }
  }

  Future<void> _onResendVerificationEmailRequested(
    ResendVerificationEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AuthVerificationRequired) return;

    final user = currentState.user;
    emit(AuthLoading());

    try {
      await _sendVerificationEmail();
      emit(AuthVerificationRequired(
        user: user,
        message: 'Verification email sent to ${user.email}.',
      ));
    } catch (error) {
      emit(AuthVerificationRequired(
        user: user,
        message: 'Could not send email: $error',
      ));
    }
  }

  Future<void> _onCheckEmailVerificationRequested(
    CheckEmailVerificationRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AuthVerificationRequired) return;

    final UserEntity user = currentState.user;
    emit(AuthLoading());

    try {
      if (await _isEmailVerified()) {
        emit(AuthAuthenticated(user: user));
      } else {
        emit(AuthVerificationRequired(
          user: user,
          message: 'Your email is not verified yet. Check your inbox.',
        ));
      }
    } catch (error) {
      emit(AuthVerificationRequired(
        user: user,
        message: 'Could not check verification: $error',
      ));
    }
  }
}
    

