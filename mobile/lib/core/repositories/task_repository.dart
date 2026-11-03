import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../errors/app_exception.dart';
import '../models/enums.dart';
import '../models/task.dart';
import '../utils/ids.dart';
import '../utils/validators.dart';

abstract interface class TaskRepository {
  /// Every task in the workspace, with subtask counts.
  Stream<List<Task>> watchByWorkspace(String workspaceId);
  Stream<Task?> watch(String id);
  Future<Task?> get(String id);
  Future<Task> create({
    required String workspaceId,
    required String title,
    String description,
    TaskStatus status,
    Priority priority,
    String? dueDate,
    String? dueTime,
    Recurrence? recurrence,
    List<String> tags,
    String? projectId,
  });

  /// Saves every editable field of [task]. Manages `completedAt` and `updatedAt`.
  Future<Task> update(Task task);
  Future<void> delete(String id);

  /// Captures a task and its subtasks so a deletion can be undone.
  Future<TaskSnapshot?> snapshot(String id);
  Future<void> restore(TaskSnapshot snapshot);

  Stream<List<Subtask>> watchSubtasks(String taskId);
  Future<List<Subtask>> getSubtasks(String taskId);
  Future<Subtask> addSubtask(String taskId, String title, {bool isDone});
  Future<Subtask> updateSubtask(Subtask subtask);
  Future<void> deleteSubtask(String id);
  Future<void> reorderSubtasks(List<String> orderedIds);
}

class DriftTaskRepository implements TaskRepository {
  DriftTaskRepository(this._db);

  final AppDatabase _db;

  static const _selectWithCounts = '''
    SELECT t.*,
      (SELECT COUNT(*) FROM subtasks s WHERE s.task_id = t.id) AS subtask_count,
      (SELECT COUNT(*) FROM subtasks s WHERE s.task_id = t.id AND s.is_done = 1) AS subtasks_done
    FROM tasks t
  ''';

  static Task _toModel(TaskRow r, {int subtaskCount = 0, int subtasksDone = 0}) => Task(
    id: r.id,
    workspaceId: r.workspaceId,
    projectId: r.projectId,
    title: r.title,
    description: r.description,
    status: TaskStatus.fromWire(r.status),
    priority: Priority.fromWire(r.priority),
    dueDate: r.dueDate,
    dueTime: r.dueTime,
    recurrence: Recurrence.tryWire(r.recurrence),
    tags: r.tags,
    sortOrder: r.sortOrder,
    completedAt: r.completedAt == null ? null : DateTime.fromMillisecondsSinceEpoch(r.completedAt!),
    createdAt: DateTime.fromMillisecondsSinceEpoch(r.createdAt),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(r.updatedAt),
    subtaskCount: subtaskCount,
    subtasksDone: subtasksDone,
  );

  Task _fromQueryRow(QueryRow row) => _toModel(
    _db.tasks.map(row.data),
    subtaskCount: row.read<int>('subtask_count'),
    subtasksDone: row.read<int>('subtasks_done'),
  );

  static Subtask _subtaskToModel(SubtaskRow r) => Subtask(
    id: r.id,
    taskId: r.taskId,
    title: r.title,
    isDone: r.isDone,
    sortOrder: r.sortOrder,
    createdAt: DateTime.fromMillisecondsSinceEpoch(r.createdAt),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(r.updatedAt),
  );

  static SubtaskRow _subtaskToRow(Subtask s) => SubtaskRow(
    id: s.id,
    taskId: s.taskId,
    title: s.title,
    isDone: s.isDone,
    sortOrder: s.sortOrder,
    createdAt: s.createdAt.millisecondsSinceEpoch,
    updatedAt: s.updatedAt.millisecondsSinceEpoch,
  );

  /// Validates and normalises the editable fields of a task.
  static TaskRow _validRow(TaskRow r) {
    final dueDate = Validators.isoDate(r.dueDate);
    return r.copyWith(
      title: Validators.name(r.title, label: 'Task title', max: 200, field: 'title'),
      description: Validators.text(r.description, label: 'Notes', max: 10000, field: 'description'),
      dueDate: Value(dueDate),
      // A time only makes sense on a dated task.
      dueTime: Value(dueDate == null ? null : Validators.time(r.dueTime)),
      tags: Validators.tags(r.tags),
    );
  }

  @override
  Stream<List<Task>> watchByWorkspace(String workspaceId) => _db
      .customSelect(
        '$_selectWithCounts WHERE t.workspace_id = ?1 ORDER BY t.sort_order',
        variables: [Variable.withString(workspaceId)],
        readsFrom: {_db.tasks, _db.subtasks},
      )
      .watch()
      .map((rows) => rows.map(_fromQueryRow).toList());

  @override
  Stream<Task?> watch(String id) => _db
      .customSelect(
        '$_selectWithCounts WHERE t.id = ?1',
        variables: [Variable.withString(id)],
        readsFrom: {_db.tasks, _db.subtasks},
      )
      .watchSingleOrNull()
      .map((row) => row == null ? null : _fromQueryRow(row));

  @override
  Future<Task?> get(String id) async {
    final row = await _db
        .customSelect('$_selectWithCounts WHERE t.id = ?1', variables: [Variable.withString(id)])
        .getSingleOrNull();
    return row == null ? null : _fromQueryRow(row);
  }

  @override
  Future<Task> create({
    required String workspaceId,
    required String title,
    String description = '',
    TaskStatus status = TaskStatus.todo,
    Priority priority = Priority.medium,
    String? dueDate,
    String? dueTime,
    Recurrence? recurrence,
    List<String> tags = const [],
    String? projectId,
  }) async {
    final ts = nowMs().millisecondsSinceEpoch;
    final row = _validRow(
      TaskRow(
        id: newId(),
        workspaceId: workspaceId,
        projectId: projectId,
        title: title,
        description: description,
        status: status.wire,
        priority: priority.wire,
        dueDate: dueDate,
        dueTime: dueTime,
        recurrence: recurrence?.wire,
        tags: tags,
        // Creation time keeps new tasks after existing ones.
        sortOrder: ts.toDouble(),
        completedAt: status == TaskStatus.completed ? ts : null,
        createdAt: ts,
        updatedAt: ts,
      ),
    );
    await _db.into(_db.tasks).insert(row);
    return _toModel(row);
  }

  @override
  Future<Task> update(Task task) {
    return _db.transaction(() async {
      final existing = await (_db.select(_db.tasks)..where((t) => t.id.equals(task.id))).getSingleOrNull();
      if (existing == null) throw NotFoundException('Task', task.id);
      final ts = nowMs().millisecondsSinceEpoch;
      final completing = task.status == TaskStatus.completed;
      final row = _validRow(
        existing.copyWith(
          projectId: Value(task.projectId),
          title: task.title,
          description: task.description,
          status: task.status.wire,
          priority: task.priority.wire,
          dueDate: Value(task.dueDate),
          dueTime: Value(task.dueTime),
          recurrence: Value(task.recurrence?.wire),
          tags: task.tags,
          sortOrder: task.sortOrder,
          completedAt: Value(completing ? (existing.completedAt ?? ts) : null),
          updatedAt: ts,
        ),
      );
      await _db.update(_db.tasks).replace(row);
      return _toModel(row, subtaskCount: task.subtaskCount, subtasksDone: task.subtasksDone);
    });
  }

  @override
  Future<void> delete(String id) async {
    await _db.transaction(() async {
      await (_db.delete(_db.tasks)..where((t) => t.id.equals(id))).go();
      await (_db.delete(_db.recentVisits)..where((r) => r.entityId.equals(id))).go();
    });
  }

  @override
  Future<TaskSnapshot?> snapshot(String id) async {
    final task = await get(id);
    if (task == null) return null;
    return TaskSnapshot(task: task, subtasks: await getSubtasks(id));
  }

  @override
  Future<void> restore(TaskSnapshot snapshot) async {
    final t = snapshot.task;
    await _db.transaction(() async {
      await _db
          .into(_db.tasks)
          .insertOnConflictUpdate(
            TaskRow(
              id: t.id,
              workspaceId: t.workspaceId,
              projectId: t.projectId,
              title: t.title,
              description: t.description,
              status: t.status.wire,
              priority: t.priority.wire,
              dueDate: t.dueDate,
              dueTime: t.dueTime,
              recurrence: t.recurrence?.wire,
              tags: t.tags,
              sortOrder: t.sortOrder,
              completedAt: t.completedAt?.millisecondsSinceEpoch,
              createdAt: t.createdAt.millisecondsSinceEpoch,
              updatedAt: t.updatedAt.millisecondsSinceEpoch,
            ),
          );
      for (final s in snapshot.subtasks) {
        await _db.into(_db.subtasks).insertOnConflictUpdate(_subtaskToRow(s));
      }
    });
  }

  SimpleSelectStatement<$SubtasksTable, SubtaskRow> _subtasksOf(String taskId) => _db.select(_db.subtasks)
    ..where((s) => s.taskId.equals(taskId))
    ..orderBy([(s) => OrderingTerm.asc(s.sortOrder)]);

  @override
  Stream<List<Subtask>> watchSubtasks(String taskId) =>
      _subtasksOf(taskId).watch().map((rows) => rows.map(_subtaskToModel).toList());

  @override
  Future<List<Subtask>> getSubtasks(String taskId) async =>
      (await _subtasksOf(taskId).get()).map(_subtaskToModel).toList();

  @override
  Future<Subtask> addSubtask(String taskId, String title, {bool isDone = false}) {
    return _db.transaction(() async {
      final maxOrder = _db.subtasks.sortOrder.max();
      final last = await (_db.selectOnly(_db.subtasks)
            ..addColumns([maxOrder])
            ..where(_db.subtasks.taskId.equals(taskId)))
          .map((r) => r.read(maxOrder))
          .getSingle();
      final ts = nowMs().millisecondsSinceEpoch;
      final row = SubtaskRow(
        id: newId(),
        taskId: taskId,
        title: Validators.name(title, label: 'Subtask', max: 200, field: 'title'),
        isDone: isDone,
        sortOrder: (last ?? 0) + 1,
        createdAt: ts,
        updatedAt: ts,
      );
      await _db.into(_db.subtasks).insert(row);
      return _subtaskToModel(row);
    });
  }

  @override
  Future<Subtask> updateSubtask(Subtask subtask) async {
    final row = _subtaskToRow(
      subtask.copyWith(
        title: Validators.name(subtask.title, label: 'Subtask', max: 200, field: 'title'),
        updatedAt: nowMs(),
      ),
    );
    final updated = await _db.update(_db.subtasks).replace(row);
    if (!updated) throw NotFoundException('Subtask', subtask.id);
    return _subtaskToModel(row);
  }

  @override
  Future<void> deleteSubtask(String id) async {
    await (_db.delete(_db.subtasks)..where((s) => s.id.equals(id))).go();
  }

  @override
  Future<void> reorderSubtasks(List<String> orderedIds) async {
    await _db.batch((b) {
      for (var i = 0; i < orderedIds.length; i++) {
        b.update(_db.subtasks, SubtasksCompanion(sortOrder: Value(i.toDouble())), where: (s) => s.id.equals(orderedIds[i]));
      }
    });
  }
}
