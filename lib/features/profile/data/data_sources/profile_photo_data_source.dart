abstract class ProfilePhotoDataSource {
  /// Uploads a gallery photo and returns its HTTPS URL.
  Future<String> uploadPhoto({required String filePath});
}
