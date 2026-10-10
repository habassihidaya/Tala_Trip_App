import 'package:equatable/equatable.dart';
import 'user_role.dart';

class UserEntity extends Equatable {
  final String id;
  final String username;
  final String email;
  final String mobileNumber;
  final UserRole role;
  final String?
  profileImageUrl; // new user might not have uploaded a profile picture yet.
  final DateTime?
  lastUsernameChangeAt; // new user might not have changed their username yet.

  const UserEntity({
    required this.id,
    required this.username,
    required this.email,
    required this.mobileNumber,
    required this.role,
    this.profileImageUrl,
    this.lastUsernameChangeAt,
  });
  @override
  List<Object?> get props => [
    id,
    username,
    email,
    mobileNumber,
    role,
    profileImageUrl,
    lastUsernameChangeAt,
  ];
}
