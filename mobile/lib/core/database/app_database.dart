import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

export 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Workspaces, Folders, Projects, Tasks, Subtasks, Pages, Drawings, RecentVisits, Preferences],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _open());

  static QueryExecutor _open() => driftDatabase(name: 'devspace');

  /// Bump this and add a step to [_upgrades] for every schema change.
  /// Snapshots live in `drift_schemas/` (`dart run drift_dev make-migrations`).
  @override
  int get schemaVersion => 1;

  /// `from -> migration to from + 1`.
  static final Map<int, Future<void> Function(Migrator m, AppDatabase db)> _upgrades = {};

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      for (var version = from; version < to; version++) {
        final step = _upgrades[version];
        if (step == null) throw StateError('Missing migration from schema v$version');
        await step(m, this);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
