import 'package:url_launcher/url_launcher.dart';

class BookingContactLauncher {
  static Future<bool> call(String phoneNumber) {
    final cleaned = phoneNumber.replaceAll(
      RegExp(r'[^0-9+]'),
      '',
    );

    return _tryOpen(
      Uri(
        scheme: 'tel',
        path: cleaned,
      ),
    );
  }

  static Future<bool> openWhatsApp(String phoneNumber) async {
    final internationalNumber = _toInternationalNumber(phoneNumber);

    if (internationalNumber == null) {
      return false;
    }

    final appOpened = await _tryOpen(
      Uri.parse(
        'whatsapp://send?phone=$internationalNumber',
      ),
    );

    if (appOpened) return true;

    // Fallback: open WhatsApp Web or the browser page.
    return _tryOpen(
      Uri.https(
        'wa.me',
        '/$internationalNumber',
      ),
    );
  }

  static String? _toInternationalNumber(String phoneNumber) {
    final cleaned = phoneNumber.replaceAll(
      RegExp(r'[^0-9+]'),
      '',
    );

    if (cleaned.startsWith('+213')) {
      return cleaned.substring(1);
    }

    if (cleaned.startsWith('00213')) {
      return cleaned.substring(2);
    }

    if (cleaned.startsWith('0')) {
      return '213${cleaned.substring(1)}';
    }

    return null;
  }

  static Future<bool> _tryOpen(Uri uri) async {
    try {
      return await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
  }
}