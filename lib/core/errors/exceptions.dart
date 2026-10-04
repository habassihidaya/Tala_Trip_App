class UnauthenticatedException implements Exception {
  const UnauthenticatedException();
}

class UserProfileNotFoundException implements Exception {
  const UserProfileNotFoundException();
}
class HotelNotFoundException implements Exception {
  const HotelNotFoundException();
}
class HotelOperationException implements Exception {
  final String message;

  const HotelOperationException(this.message);
}