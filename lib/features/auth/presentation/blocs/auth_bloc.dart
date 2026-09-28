import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tala_trip_app/features/auth/domain/usecases/auth_usecases.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required SignUp signUp})
      : _signUp = signUp,
        super(AuthInitial()) {
    on<SignUpRequested>(_onSignUpRequested);
  }

  final SignUp _signUp;

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

      emit(AuthAuthenticated(user :user));
    } catch (error) {
      emit(AuthError(message: error.toString()));
    }
  }
}