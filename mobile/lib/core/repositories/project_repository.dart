import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../errors/app_exception.dart';
import '../models/enums.dart';
import '../models/project.dart';
import '../utils/ids.dart';
import '../utils/validators.dart';

abstract interface class ProjectRepository {
  /// Every project in the workspace, with linked task counts.
  Stream<List<Project>> watchByWorkspace(String workspaceId);
  Stream<Project?> watch(String id);
  Future<Project> create({
    required String workspaceId,
    required String name,
    String description,
    ProjectStatus status,
    Priority priority,
    ProjectColor color,
    String? startDate,
    String? dueDate,
  });
  Future<Project> update(Project project);

  /// Deletes the project; its tasks, notes and drawings stay, unlinked.
  Future<void> delete(String id);
}

class DriftProjectRepository implements ProjectRepository {
  DriftProjectRepository(this._db);

  final AppDatabase _db;

  static const _selectWithCounts = '''
    SELECT p.*,
      (SELECT COUNT(*) FROM tasks t WHERE t.project_id = p.id) AS task_count,
      (SELECT COUNT(*) FROM tasks t WHERE t.project_id = p.id AND t.status = 'completed') AS completed_count
    FROM projects p
  ''';

  static Project _toModel(ProjectRow r, {int taskCount = 0, int completed = 0}) => Project(
    id: r.id,
    workspaceId: r.workspaceId,
    name: r.name,
    description: r.description,
    status: ProjectStatus.fromWire(r.status),
    priority: Priority.fromWire(r.priority),
    color: ProjectColor.fromWire(r.color),
    startDate: r.startDate,
    dueDate: r.dueDate,
    createdAt: DateTime.fromMillisecondsSinceEpoch(r.createdAt),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(r.updatedAt),
    taskCount: taskCount,
    completedTaskCount: completed,
  );

  Project _fromQueryRow(QueryRow row) => _toModel(
    _db.projects.map(row.data),
    taskCount: row.read<int>('task_count'),
    completed: row.read<int>('completed_count'),
  );

  static ProjectRow _validRow(ProjectRow r) {
    final start = Validators.isoDate(r.startDate, field: 'startDate');
    final due = Validators.isoDate(r.dueDate);
    if (start != null && due != null && due.compareTo(start) < 0) {
      throw ValidationException.field('dueDate', 'Due date must be on or after the start date');
    }
    return r.copyWith(
      name: Validators.name(r.name, label: 'Project name', max: 80),
      description: Validators.text(r.description, label: 'Description', max: 5000, field: 'description'),
    );
  }

  @override
  Stream<List<Project>> watchByWorkspace(String workspaceId) => _db
      .customSelect(
        '$_selectWithCounts WHERE p.workspace_id = ?1 ORDER BY p.created_at',
        variables: [Variable.withString(workspaceId)],
        readsFrom: {_db.projects, _db.tasks},
      )
      .watch()
      .map((rows) => rows.map(_fromQueryRow).toList());

  @override
  Stream<Project?> watch(String id) => _db
      .customSelect(
        '$_selectWithCounts WHERE p.id = ?1',
        variables: [Variable.withString(id)],
        readsFrom: {_db.projects, _db.tasks},
      )
      .watchSingleOrNull()
      .map((row) => row == null ? null : _fromQueryRow(row));

  @override
  Future<Project> create({
    required String workspaceId,
    required String name,
    String description = '',
    ProjectStatus status = ProjectStatus.planning,
    Priority priority = Priority.medium,
    ProjectColor color = ProjectColor.indigo,
    String? startDate,
    String? dueDate,
  }) async {
    final ts = nowMs().millisecondsSinceEpoch;
    final row = _validRow(
      ProjectRow(
        id: newId(),
        workspaceId: workspaceId,
        name: name,
        description: description,
        status: status.wire,
        priority: priority.wire,
        color: color.wire,
        startDate: startDate,
        dueDate: dueDate,
        createdAt: ts,
        updatedAt: ts,
      ),
    );
    await _db.into(_db.projects).insert(row);
    return _toModel(row);
  }

  @override
  Future<Project> update(Project project) {
    return _db.transaction(() async {
      final existing = await (_db.select(_db.projects)..where((p) => p.id.equals(project.id))).getSingleOrNull();
      if (existing == null) throw NotFoundException('Project', project.id);
      final row = _validRow(
        existing.copyWith(
          name: project.name,
          description: project.description,
          status: project.status.wire,
          priority: project.priority.wire,
          color: project.color.wire,
          startDate: Value(project.startDate),
          dueDate: Value(project.dueDate),
          updatedAt: nowMs().millisecondsSinceEpoch,
        ),
      );
      await _db.update(_db.projects).replace(row);
      return _toModel(row, taskCount: project.taskCount, completed: project.completedTaskCount);
    });
  }

  @override
  Future<void> delete(String id) async {
    await _db.transaction(() async {
      // Foreign keys unlink tasks, pages and drawings.
      await (_db.delete(_db.projects)..where((p) => p.id.equals(id))).go();
      await (_db.delete(_db.recentVisits)..where((r) => r.entityId.equals(id))).go();
    });
  }
}
