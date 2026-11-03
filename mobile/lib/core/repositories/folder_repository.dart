import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../errors/app_exception.dart';
import '../models/enums.dart';
import '../models/folder.dart';
import '../utils/ids.dart';
import '../utils/validators.dart';

abstract interface class FolderRepository {
  Stream<List<Folder>> watchByWorkspace(String workspaceId, {FolderKind? kind});
  Future<Folder> create({required String workspaceId, required FolderKind kind, required String name});
  Future<Folder> rename(String id, String name);

  /// Deletes the folder; its items move to the top level.
  Future<void> delete(String id);
}

class DriftFolderRepository implements FolderRepository {
  DriftFolderRepository(this._db);

  final AppDatabase _db;

  static Folder _toModel(FolderRow r) => Folder(
    id: r.id,
    workspaceId: r.workspaceId,
    kind: FolderKind.fromWire(r.kind),
    name: r.name,
    createdAt: DateTime.fromMillisecondsSinceEpoch(r.createdAt),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(r.updatedAt),
  );

  @override
  Stream<List<Folder>> watchByWorkspace(String workspaceId, {FolderKind? kind}) {
    final query = _db.select(_db.folders)
      ..where((f) => f.workspaceId.equals(workspaceId) & (kind == null ? const Constant(true) : f.kind.equals(kind.wire)))
      ..orderBy([(f) => OrderingTerm.asc(f.name.collate(Collate.noCase))]);
    return query.watch().map((rows) => rows.map(_toModel).toList());
  }

  /// Folder names are unique per workspace and kind, ignoring case.
  Future<void> _assertUnique(String workspaceId, String kind, String name, {String? exceptId}) async {
    final clash = await (_db.select(_db.folders)
          ..where(
            (f) =>
                f.workspaceId.equals(workspaceId) &
                f.kind.equals(kind) &
                f.name.lower().equals(name.toLowerCase()) &
                (exceptId == null ? const Constant(true) : f.id.equals(exceptId).not()),
          )
          ..limit(1))
        .getSingleOrNull();
    if (clash != null) throw ValidationException.field('name', 'A folder named "$name" already exists');
  }

  @override
  Future<Folder> create({required String workspaceId, required FolderKind kind, required String name}) {
    return _db.transaction(() async {
      final trimmed = Validators.name(name, label: 'Folder name', max: 60);
      await _assertUnique(workspaceId, kind.wire, trimmed);
      final ts = nowMs().millisecondsSinceEpoch;
      final row = FolderRow(
        id: newId(),
        workspaceId: workspaceId,
        kind: kind.wire,
        name: trimmed,
        createdAt: ts,
        updatedAt: ts,
      );
      await _db.into(_db.folders).insert(row);
      return _toModel(row);
    });
  }

  @override
  Future<Folder> rename(String id, String name) {
    return _db.transaction(() async {
      final existing = await (_db.select(_db.folders)..where((f) => f.id.equals(id))).getSingleOrNull();
      if (existing == null) throw NotFoundException('Folder', id);
      final trimmed = Validators.name(name, label: 'Folder name', max: 60);
      await _assertUnique(existing.workspaceId, existing.kind, trimmed, exceptId: id);
      final next = existing.copyWith(name: trimmed, updatedAt: nowMs().millisecondsSinceEpoch);
      await _db.update(_db.folders).replace(next);
      return _toModel(next);
    });
  }

  @override
  Future<void> delete(String id) async {
    await (_db.delete(_db.folders)..where((f) => f.id.equals(id))).go();
  }
}
