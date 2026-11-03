import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../errors/app_exception.dart';
import '../models/enums.dart';
import '../models/workspace.dart';
import '../utils/ids.dart';
import '../utils/validators.dart';

/// Storage-agnostic contract. Today it is backed by SQLite; a sync-aware
/// implementation only needs to satisfy the same interface.
abstract interface class WorkspaceRepository {
  Stream<List<Workspace>> watchAll();
  Future<List<Workspace>> getAll();
  Future<Workspace?> get(String id);
  Stream<WorkspaceStats> watchStats(String id);
  Future<Workspace> create({required String name, String? icon, WorkspaceType type});
  Future<Workspace> update(String id, {String? name, String? icon, WorkspaceType? type});

  /// Removes the workspace and everything inside it.
  Future<void> delete(String id);
}

class DriftWorkspaceRepository implements WorkspaceRepository {
  DriftWorkspaceRepository(this._db);

  final AppDatabase _db;

  static Workspace _toModel(WorkspaceRow r) => Workspace(
    id: r.id,
    name: r.name,
    icon: r.icon,
    type: WorkspaceType.fromWire(r.type),
    createdAt: DateTime.fromMillisecondsSinceEpoch(r.createdAt),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(r.updatedAt),
  );

  SimpleSelectStatement<$WorkspacesTable, WorkspaceRow> get _ordered =>
      _db.select(_db.workspaces)..orderBy([(w) => OrderingTerm.asc(w.createdAt)]);

  @override
  Stream<List<Workspace>> watchAll() => _ordered.watch().map((rows) => rows.map(_toModel).toList());

  @override
  Future<List<Workspace>> getAll() async => (await _ordered.get()).map(_toModel).toList();

  @override
  Future<Workspace?> get(String id) async {
    final row = await (_db.select(_db.workspaces)..where((w) => w.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toModel(row);
  }

  @override
  Stream<WorkspaceStats> watchStats(String id) {
    return _db
        .customSelect(
          '''
          SELECT
            (SELECT COUNT(*) FROM tasks WHERE workspace_id = ?1) AS tasks,
            (SELECT COUNT(*) FROM tasks WHERE workspace_id = ?1 AND status != 'completed') AS open_tasks,
            (SELECT COUNT(*) FROM projects WHERE workspace_id = ?1) AS projects,
            (SELECT COUNT(*) FROM pages WHERE workspace_id = ?1 AND kind = 'note') AS notes,
            (SELECT COUNT(*) FROM pages WHERE workspace_id = ?1 AND kind = 'doc') AS docs,
            (SELECT COUNT(*) FROM drawings WHERE workspace_id = ?1) AS drawings,
            (SELECT COUNT(*) FROM folders WHERE workspace_id = ?1) AS folders
          ''',
          variables: [Variable.withString(id)],
          readsFrom: {_db.tasks, _db.projects, _db.pages, _db.drawings, _db.folders},
        )
        .watchSingle()
        .map(
          (row) => WorkspaceStats(
            tasks: row.read<int>('tasks'),
            openTasks: row.read<int>('open_tasks'),
            projects: row.read<int>('projects'),
            notes: row.read<int>('notes'),
            docs: row.read<int>('docs'),
            drawings: row.read<int>('drawings'),
            folders: row.read<int>('folders'),
          ),
        );
  }

  @override
  Future<Workspace> create({required String name, String? icon, WorkspaceType type = WorkspaceType.personal}) async {
    final ts = nowMs().millisecondsSinceEpoch;
    final row = WorkspaceRow(
      id: newId(),
      name: Validators.name(name, label: 'Workspace name', max: 60),
      icon: Validators.icon(icon),
      type: type.wire,
      createdAt: ts,
      updatedAt: ts,
    );
    await _db.into(_db.workspaces).insert(row);
    return _toModel(row);
  }

  @override
  Future<Workspace> update(String id, {String? name, String? icon, WorkspaceType? type}) {
    return _db.transaction(() async {
      final existing = await (_db.select(_db.workspaces)..where((w) => w.id.equals(id))).getSingleOrNull();
      if (existing == null) throw NotFoundException('Workspace', id);
      final next = existing.copyWith(
        name: name == null ? existing.name : Validators.name(name, label: 'Workspace name', max: 60),
        icon: icon == null ? existing.icon : Validators.icon(icon),
        type: type?.wire ?? existing.type,
        updatedAt: nowMs().millisecondsSinceEpoch,
      );
      await _db.update(_db.workspaces).replace(next);
      return _toModel(next);
    });
  }

  @override
  Future<void> delete(String id) async {
    // Foreign keys cascade to every workspace-scoped table.
    await (_db.delete(_db.workspaces)..where((w) => w.id.equals(id))).go();
  }
}
