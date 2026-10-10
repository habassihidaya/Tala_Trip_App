import 'package:url_launcher/url_launcher.dart';
import 'package:tala_trip_app/core/validation/international_phone.dart';

class BookingContactLauncher {
  static Future<bool> call(String phoneNumber) async {
    final cleaned = InternationalPhone.normalizeContact(phoneNumber);
    if (cleaned == null) return false;

    return _tryOpen(Uri(scheme: 'tel', path: cleaned));
  }

  static Future<bool> openWhatsApp(String phoneNumber) async {
    final normalized = InternationalPhone.normalizeContact(phoneNumber);

    if (normalized == null) {
      return false;
    }
    final internationalNumber = normalized.substring(1);

    final appOpened = await _tryOpen(
      Uri.parse('whatsapp://send?phone=$internationalNumber'),
    );

    if (appOpened) return true;

    // Fallback: open WhatsApp Web or the browser page.
    return _tryOpen(Uri.https('wa.me', '/$internationalNumber'));
  }

  static Future<bool> _tryOpen(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
