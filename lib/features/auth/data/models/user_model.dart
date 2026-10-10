import 'package:tala_trip_app/features/auth/domain/entities/user_entity.dart';
import 'package:tala_trip_app/features/auth/domain/entities/user_role.dart';

class UserModel {
  final String id;
  final String username;
  final String email;
  final String mobileNumber;
  final UserRole role;
  final String? profileImageUrl;
  final DateTime? lastUsernameChangeAt;
  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.mobileNumber,
    required this.role,
    this.profileImageUrl,
    this.lastUsernameChangeAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      mobileNumber: json['mobileNumber'] as String,
      role: UserRole.values.firstWhere(
        (role) => role.name == json['role'],
        orElse: () => UserRole.traveler,
      ),
      profileImageUrl: json['profileImageUrl'] as String?,
      lastUsernameChangeAt: json['lastUsernameChangeAt'] != null
          ? DateTime.parse(json['lastUsernameChangeAt'] as String)
          : null,
    );
  }
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      username: entity.username,
      email: entity.email,
      mobileNumber: entity.mobileNumber,
      role: entity.role,
      profileImageUrl: entity.profileImageUrl,
      lastUsernameChangeAt: entity.lastUsernameChangeAt,
    );
  }

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      username: username,
      email: email,
      mobileNumber: mobileNumber,
      role: role,
      profileImageUrl: profileImageUrl,
      lastUsernameChangeAt: lastUsernameChangeAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'mobileNumber': mobileNumber,
      'role': role.name,
      'profileImageUrl': profileImageUrl,
      'lastUsernameChangeAt': lastUsernameChangeAt?.toIso8601String(),
    };
  }
}
