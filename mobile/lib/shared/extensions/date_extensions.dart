import 'package:intl/intl.dart';

extension DateTimeDisplay on DateTime {
  /// "Good morning", "Good afternoon" or "Good evening".
  String get greeting {
    if (hour < 5) return 'Good evening';
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  /// "Monday, November 2"
  String get longWeekdayDate => DateFormat('EEEE, MMMM d').format(this);

  /// "Nov 2, 2026"
  String get mediumDate => DateFormat.yMMMd().format(this);
}
