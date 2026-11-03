import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../models/enums.dart';
import '../models/recent_visit.dart';
import '../utils/ids.dart';

/// Tracks recently opened items per workspace.
abstract interface class RecentRepository {
  Stream<List<RecentVisit>> watchByWorkspace(String workspaceId, {int limit = 12});
  Future<RecentVisit> touch({required String workspaceId, required EntityType type, required String entityId});
  Future<void> forget(EntityType type, String entityId);
}

class DriftRecentRepository implements RecentRepository {
  DriftRecentRepository(this._db);

  final AppDatabase _db;

  static RecentVisit _toModel(RecentVisitRow r) => RecentVisit(
    id: r.id,
    workspaceId: r.workspaceId,
    entityType: EntityType.fromWire(r.entityType),
    entityId: r.entityId,
    visitedAt: DateTime.fromMillisecondsSinceEpoch(r.visitedAt),
  );

  @override
  Stream<List<RecentVisit>> watchByWorkspace(String workspaceId, {int limit = 12}) {
    final query = _db.select(_db.recentVisits)
      ..where((r) => r.workspaceId.equals(workspaceId))
      ..orderBy([(r) => OrderingTerm.desc(r.visitedAt)])
      ..limit(limit);
    return query.watch().map((rows) => rows.map(_toModel).toList());
  }

  @override
  Future<RecentVisit> touch({required String workspaceId, required EntityType type, required String entityId}) async {
    final row = RecentVisitRow(
      id: '${type.wire}:$entityId',
      workspaceId: workspaceId,
      entityType: type.wire,
      entityId: entityId,
      visitedAt: nowMs().millisecondsSinceEpoch,
    );
    await _db.into(_db.recentVisits).insertOnConflictUpdate(row);
    return _toModel(row);
  }

  @override
  Future<void> forget(EntityType type, String entityId) async {
    await (_db.delete(_db.recentVisits)..where((r) => r.id.equals('${type.wire}:$entityId'))).go();
  }
}
