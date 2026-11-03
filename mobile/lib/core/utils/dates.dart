import '../models/enums.dart';

/// Calendar-day helpers. Due dates are stored as local `YYYY-MM-DD` strings,
/// like the web app, so they never shift across time zones.
abstract final class Dates {
  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static String toIso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Parses `YYYY-MM-DD` to local midnight.
  static DateTime parseIso(String iso) {
    final parts = iso.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }

  static DateTime addDays(DateTime d, int days) => DateTime(d.year, d.month, d.day + days);

  /// Whole calendar days from [from] to [to] (negative when [to] is earlier).
  static int daysBetween(DateTime from, DateTime to) =>
      DateTime.utc(to.year, to.month, to.day).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

  /// Monday of the week containing [d].
  static DateTime startOfWeek(DateTime d) => addDays(dateOnly(d), -(d.weekday - DateTime.monday));

  /// The first occurrence of [recurrence] strictly after [from].
  static DateTime nextOccurrence(Recurrence recurrence, DateTime from) {
    final d = dateOnly(from);
    switch (recurrence) {
      case Recurrence.daily:
        return addDays(d, 1);
      case Recurrence.weekdays:
        var next = addDays(d, 1);
        while (next.weekday == DateTime.saturday || next.weekday == DateTime.sunday) {
          next = addDays(next, 1);
        }
        return next;
      case Recurrence.weekly:
        return addDays(d, 7);
      case Recurrence.monthly:
        return _addMonths(d, 1);
      case Recurrence.yearly:
        return _addMonths(d, 12);
    }
  }

  /// Same day-of-month, clamped to the last day (Jan 31 → Feb 28).
  static DateTime _addMonths(DateTime d, int months) {
    final firstOfTarget = DateTime(d.year, d.month + months);
    final lastDay = DateTime(firstOfTarget.year, firstOfTarget.month + 1, 0).day;
    return DateTime(firstOfTarget.year, firstOfTarget.month, d.day > lastDay ? lastDay : d.day);
  }
}
