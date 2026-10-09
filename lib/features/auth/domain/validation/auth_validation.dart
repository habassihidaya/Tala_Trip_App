class AuthValidation {
  AuthValidation._();

  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;

  static String? email(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Enter your email address.';
    }

    final validFormat = RegExp(
      r'^[^@\s]+@[^@\s.]+(?:\.[^@\s.]+)+$',
    ).hasMatch(email);

    if (!validFormat) {
      return 'Enter a valid email address.';
    }

    return null;
  }

  static String? signInPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Enter your password.';
    }

    return null;
  }

  static String? newPassword(String? value) {
    final password = value ?? '';

    if (password.isEmpty) {
      return 'Enter your password.';
    }

    final length = password.runes.length;

    if (length < minPasswordLength) {
      return 'Use at least 8 characters. ';
    }

    if (length > maxPasswordLength) {
      return 'Use no more than 128 characters.';
    }

    return null;
  }

  static String? confirmPassword(String? value, String originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Confirm your password.';
    }

    if (value != originalPassword) {
      return 'Passwords do not match.';
    }

    return null;
  }
}
