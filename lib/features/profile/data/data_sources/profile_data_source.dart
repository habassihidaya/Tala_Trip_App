import '../../../auth/data/models/user_model.dart';

abstract class ProfileDataSource {
  /// Reads the currently signed-in user's profile.
  Future<UserModel> getProfile();

  /// Saves the new name in Firestore.
  Future<UserModel> updateName({required String username});

  /// Saves the uploaded photo's URL in Firestore.
  Future<UserModel> updatePhotoUrl({
    required String photoUrl,
    required String expectedUserId,
  });
}
