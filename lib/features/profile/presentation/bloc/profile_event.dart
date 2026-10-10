abstract class ProfileEvent {
  const ProfileEvent();
}

class ProfileRequested extends ProfileEvent {
  const ProfileRequested();
}

class ProfileNameUpdateRequested extends ProfileEvent {
  final String username;

  const ProfileNameUpdateRequested({required this.username});
}

class ProfilePhotoUpdateRequested extends ProfileEvent {
  final String filePath;

  const ProfilePhotoUpdateRequested({required this.filePath});
}
