abstract class AuthEvent {}
class SignUpRequested extends AuthEvent {
  final String username;
  final String email;
  final String password;
  final String mobileNumber;

  SignUpRequested({
    required this.username,
    required this.email,
    required this.password,
    required this.mobileNumber});
}

class SignInRequested extends AuthEvent {
  final String email;
  final String password;

  SignInRequested({
    required this.email,
    required this.password});
}

class ResendVerificationEmailRequested extends AuthEvent {}

class CheckEmailVerificationRequested extends AuthEvent {}