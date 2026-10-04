class HotelValidation {
  static const wilayas = ['Alger', 'Oran', 'Béjaïa', 'Annaba', 'Tipaza'];
  static const maxPhotos = 10;
  static String normalizePhone(String value) =>
      value.trim().replaceAll(RegExp(r'[\s()-]'), '');
  static bool validPhone(String value) => RegExp(
    r'^(0[1-9][0-9]{7,8}|\+213[1-9][0-9]{7,8})$',
  ).hasMatch(normalizePhone(value));
  static bool validImage(String value) =>
      value.length <= 2048 &&
      RegExp(r'^https://res\.cloudinary\.com/[^\s]+$').hasMatch(value);
  static bool validMap(String value) =>
      value.length <= 2048 &&
      RegExp(
        r'^https://((www\.)?google\.(com|dz|fr)/maps([/?][^\s]*)?|maps\.google\.com/[^\s]*|maps\.app\.goo\.gl/[^\s]+|goo\.gl/maps/[^\s]+)$',
      ).hasMatch(value);

  static String? draft({
    required String name,
    required String description,
    required String wilaya,
    required String address,
    required String phoneNumber,
    required int photoCount,
    String? mapUrl,
  }) {
    if (name.trim().isEmpty || name.trim().length > 120) {
      return 'Enter a hotel name of 1–120 characters.';
    }
    if (description.trim().length > 5000) {
      return 'Description must be at most 5,000 characters.';
    }
    if (wilaya.isNotEmpty && !wilayas.contains(wilaya)) {
      return 'Choose one of the five supported wilayas.';
    }
    if (address.trim().length > 500) {
      return 'Address must be at most 500 characters.';
    }
    if (phoneNumber.trim().isNotEmpty && !validPhone(phoneNumber)) {
      return 'Enter a valid Algerian phone number.';
    }
    if (photoCount > maxPhotos) return 'Choose at most 10 photos.';
    if (mapUrl != null &&
        mapUrl.trim().isNotEmpty &&
        !validMap(mapUrl.trim())) {
      return 'Use an HTTPS Google Maps link or leave it empty.';
    }
    return null;
  }
}
