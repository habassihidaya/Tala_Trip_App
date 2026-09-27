import 'package:equatable/equatable.dart';
class UserEntity extends Equatable {
  final String id;
  final String username;
  final String email;
  final String mobileNumber;
  final String? profileImageUrl; // new user might not have uploaded a profile picture yet.
  final DateTime? lastUsernameChangeAt; // new user might not have changed their username yet.
}

const UserEntity({
  required this.id,
  required this.username,
  required this.email,
  required this.mobileNumber,
  this.profileImageUrl,
  this.lastUsernameChangeAt,
});
@override
List<Object?> get props => [
  id,
  username,
  email,
  mobileNumber,
  profileImageUrl,
  lastUsernameChangeAt,
];