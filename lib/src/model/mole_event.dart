import 'package:timezone/timezone.dart' as tz;

class MoleEvent {
  final DateTime time;
  final String desc;

  MoleEvent(this.time, this.desc);

  factory MoleEvent.fromJson(data) {
    String dayOfWeek = data["day"]; // e.g., "Monday", "Tuesday", etc.
    int hour = data["hour"]; // 0-23
    int minute = data["minute"];
    String zone = "America/Los_Angeles"; //.data["zone"]; // e.g., "America/New_York"
    String desc = data["desc"];

    // Get the timezone
    final location = tz.getLocation(zone); //print("Location: $location");

    // Get current time in the specified timezone
    final now = tz.TZDateTime.now(location);

    // Convert day name to day number (1=Monday, 7=Sunday)
    final targetDayNum = _getDayNumber(dayOfWeek);

    // Calculate days until target day of week
    int daysUntil = ((targetDayNum - now.weekday) % 7).floor();
    if (daysUntil == 0) {
      // Same day - check if time has already passed
      final targetTime = now.copyWith(hour: hour, minute: minute, second: 0, millisecond: 0, microsecond: 0);
      if (targetTime.isBefore(now)) {
        daysUntil = 7; // Move to next week
      }
    }

    // Calculate the target date
    final targetDate = now.add(Duration(days: daysUntil));

    // Create the final datetime with specified time
    final result = tz.TZDateTime(
      location,
      targetDate.year,
      targetDate.month,
      targetDate.day,
      hour,
      minute,
    );

    final millisecondsSinceEpoch = result.millisecondsSinceEpoch;
    final plainDateTime = DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
    final localTime = plainDateTime.toLocal();

    return MoleEvent(localTime, desc);
  }

  /// Converts day name to weekday number (1=Monday, 7=Sunday)
  static int _getDayNumber(String dayName) {
    const dayMap = {
      'monday': 1,
      'tuesday': 2,
      'wednesday': 3,
      'thursday': 4,
      'friday': 5,
      'saturday': 6,
      'sunday': 7,
    };

    return dayMap[dayName.toLowerCase()] ?? 1;
  }
}
