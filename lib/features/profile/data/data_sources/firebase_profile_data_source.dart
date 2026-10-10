import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../auth/data/models/user_model.dart';
import 'profile_data_source.dart';

class FirebaseProfileDataSource implements ProfileDataSource {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirebaseProfileDataSource({required this._auth, required this._firestore});

  String _requireUserId() {
    final user = _auth.currentUser;

    if (user == null) {
      throw const UnauthenticatedException();
    }

    return user.uid;
  }

  void _checkSession(String userId) {
    if (_auth.currentUser?.uid != userId) {
      throw const UnauthenticatedException();
    }
  }

  @override
  Future<UserModel> getProfile() async {
    final userId = _requireUserId();

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .get(const GetOptions(source: Source.server));

    _checkSession(userId);

    final data = snapshot.data();

    if (data == null) {
      throw const UserProfileNotFoundException();
    }

    return UserModel.fromJson({...data, 'id': userId});
  }

  @override
  Future<UserModel> updateName({required String username}) {
    final name = username.trim();

    if (name.isEmpty || name.length > 120) {
      throw ArgumentError(
        'Your name must contain between 1 and 120 characters.',
      );
    }

    return _updateProfile({
      'username': name,
      'lastUsernameChangeAt': DateTime.now().toUtc().toIso8601String(),
    });
  }

  @override
  Future<UserModel> updatePhotoUrl({
    required String photoUrl,
    required String expectedUserId,
  }) {
    _checkSession(expectedUserId);

    final url = photoUrl.trim();
    final uri = Uri.tryParse(url);

    if (url.length > 2048 ||
        uri == null ||
        uri.scheme != 'https' ||
        uri.host != 'res.cloudinary.com' ||
        uri.pathSegments.isEmpty) {
      throw ArgumentError('Invalid profile photo URL.');
    }

    return _updateProfile({'profileImageUrl': url});
  }

  Future<UserModel> _updateProfile(Map<String, dynamic> changes) async {
    final userId = _requireUserId();
    final reference = _firestore.collection('users').doc(userId);

    final updatedUser = await _firestore.runTransaction<UserModel>((
      transaction,
    ) async {
      final snapshot = await transaction.get(reference);

      _checkSession(userId);

      final data = snapshot.data();

      if (data == null) {
        throw const UserProfileNotFoundException();
      }

      final updatedModel = UserModel.fromJson({
        ...data,
        ...changes,
        'id': userId,
      });

      transaction.update(reference, changes);

      return updatedModel;
    });

    _checkSession(userId);

    return updatedUser;
  }
}
