import '../database/app_database.dart';

enum PreferenceKey { activeWorkspaceId, themeMode, displayName }

/// Small key–value settings stored in SQLite alongside the user's data.
abstract interface class PreferencesRepository {
  Stream<String?> watch(PreferenceKey key);
  Future<String?> get(PreferenceKey key);

  /// Writes [value], or removes the key when [value] is null.
  Future<void> set(PreferenceKey key, String? value);
}

class DriftPreferencesRepository implements PreferencesRepository {
  DriftPreferencesRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<String?> watch(PreferenceKey key) =>
      (_db.select(_db.preferences)..where((p) => p.key.equals(key.name))).watchSingleOrNull().map((r) => r?.value);

  @override
  Future<String?> get(PreferenceKey key) async =>
      (await (_db.select(_db.preferences)..where((p) => p.key.equals(key.name))).getSingleOrNull())?.value;

  @override
  Future<void> set(PreferenceKey key, String? value) async {
    if (value == null) {
      await (_db.delete(_db.preferences)..where((p) => p.key.equals(key.name))).go();
    } else {
      await _db.into(_db.preferences).insertOnConflictUpdate(PreferenceRow(key: key.name, value: value));
    }
  }
}
