import '../errors/app_exception.dart';

/// Validation rules shared by every repository. They mirror the web app's
/// Zod schemas so data stays compatible when sync arrives.
abstract final class Validators {
  /// Trims [value] and checks it is non-empty and at most [max] characters.
  static String name(String? value, {required String label, int max = 120, String field = 'name'}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) throw ValidationException.field(field, '$label is required');
    if (trimmed.length > max) {
      throw ValidationException.field(field, '$label must be $max characters or fewer');
    }
    return trimmed;
  }

  /// Workspace and folder icons are short emoji strings.
  static String icon(String? value, {String fallback = '🚀'}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return fallback;
    if (trimmed.length > 16) throw ValidationException.field('icon', 'Pick a single emoji');
    return trimmed;
  }

  static final _isoDate = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  /// Dates are stored as `YYYY-MM-DD` strings, like the web app.
  static String? isoDate(String? value, {String field = 'dueDate'}) {
    if (value == null) return null;
    if (!_isoDate.hasMatch(value)) {
      throw ValidationException.field(field, 'Dates must be in YYYY-MM-DD format');
    }
    return value;
  }

  /// Trims [value] and enforces a maximum length; empty is allowed.
  static String text(String? value, {required String label, required int max, required String field}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.length > max) throw ValidationException.field(field, '$label must be $max characters or fewer');
    return trimmed;
  }

  static final _time = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

  /// Times are `HH:mm`, 24-hour.
  static String? time(String? value) {
    if (value == null) return null;
    if (!_time.hasMatch(value)) throw ValidationException.field('dueTime', 'Times must be in HH:mm format');
    return value;
  }

  /// Trims, drops blanks and duplicates (case-insensitive), max 20 tags of 32 chars.
  static List<String> tags(List<String> value) {
    final seen = <String>{};
    final result = <String>[];
    for (final raw in value) {
      final tag = raw.trim().replaceFirst(RegExp(r'^#'), '');
      if (tag.isEmpty || !seen.add(tag.toLowerCase())) continue;
      if (tag.length > 32) throw ValidationException.field('tags', 'Tags must be 32 characters or fewer');
      result.add(tag);
    }
    if (result.length > 20) throw ValidationException.field('tags', 'A task can have at most 20 tags');
    return result;
  }
}
