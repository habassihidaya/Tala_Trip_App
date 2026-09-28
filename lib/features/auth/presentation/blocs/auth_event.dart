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