import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class AlgeriaTime {
  final tz.Location _location;

  AlgeriaTime._(this._location);

  factory AlgeriaTime.initialize() {
    tz_data.initializeTimeZones();

    return AlgeriaTime._(
      tz.getLocation('Africa/Algiers'),
    );
  }

  // Convert an actual instant into Algeria's local time.
  DateTime toAlgeriaTime(DateTime instant) {
    return tz.TZDateTime.from(instant, _location);
  }

  // Return Algeria's calendar date using our date-only convention.
  // The result represents a date, not an actual midnight instant.
  DateTime today({
    required DateTime now,
  }) {
    final local = toAlgeriaTime(now);

    return DateTime.utc(
      local.year,
      local.month,
      local.day,
    );
  }

  // Convert midnight at the start of an Algeria calendar date
  // into an actual UTC instant.
  DateTime startOfDayUtc(DateTime calendarDate) {
    return tz.TZDateTime(
      _location,
      calendarDate.year,
      calendarDate.month,
      calendarDate.day,
    ).toUtc();
  }
}