import 'package:devspace/core/database/app_database.dart';
import 'package:devspace/core/errors/app_exception.dart';
import 'package:devspace/core/models/enums.dart';
import 'package:devspace/core/repositories/project_repository.dart';
import 'package:devspace/core/repositories/recent_repository.dart';
import 'package:devspace/core/repositories/task_repository.dart';
import 'package:devspace/core/repositories/workspace_repository.dart';
import 'package:devspace/core/services/task_service.dart';
import 'package:devspace/core/services/widget_bridge.dart';
import 'package:devspace/features/widgets/widget_sync.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DriftTaskRepository tasks;
  late DriftProjectRepository projects;
  late TaskService service;
  late String ws;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    tasks = DriftTaskRepository(db);
    projects = DriftProjectRepository(db);
    service = TaskService(tasks, DriftRecentRepository(db), clock: () => DateTime(2026, 11, 4, 10));
    ws = (await DriftWorkspaceRepository(db).create(name: 'W')).id;
  });

  tearDown(() => db.close());

  group('TaskRepository', () {
    test('create validates and normalises', () async {
      final t = await tasks.create(workspaceId: ws, title: '  Ship it ', tags: ['#ios', 'iOS', ' ', 'release']);
      expect(t.title, 'Ship it');
      expect(t.tags, ['ios', 'release']);
      expect(() => tasks.create(workspaceId: ws, title: ''), throwsA(isA<ValidationException>()));
      expect(
        () => tasks.create(workspaceId: ws, title: 'x', dueDate: '2026-11-04', dueTime: '25:00'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('a time without a date is dropped', () async {
      final t = await tasks.create(workspaceId: ws, title: 'x', dueTime: '09:00');
      expect(t.dueTime, isNull);
    });

    test('completedAt follows status', () async {
      final t = await tasks.create(workspaceId: ws, title: 'x');
      final done = await tasks.update(t.copyWith(status: TaskStatus.completed));
      expect(done.completedAt, isNotNull);
      final reopened = await tasks.update(done.copyWith(status: TaskStatus.todo));
      expect(reopened.completedAt, isNull);
    });

    test('watch includes subtask counts and deleting cascades', () async {
      final t = await tasks.create(workspaceId: ws, title: 'Parent');
      final a = await tasks.addSubtask(t.id, 'one');
      await tasks.addSubtask(t.id, 'two');
      await tasks.updateSubtask(a.copyWith(isDone: true));
      final listed = (await tasks.watchByWorkspace(ws).first).single;
      expect(listed.subtaskCount, 2);
      expect(listed.subtasksDone, 1);

      await tasks.delete(t.id);
      expect(await db.select(db.subtasks).get(), isEmpty);
    });

    test('subtasks keep their order and can be reordered', () async {
      final t = await tasks.create(workspaceId: ws, title: 'P');
      final a = await tasks.addSubtask(t.id, 'a');
      final b = await tasks.addSubtask(t.id, 'b');
      expect((await tasks.getSubtasks(t.id)).map((s) => s.title), ['a', 'b']);
      await tasks.reorderSubtasks([b.id, a.id]);
      expect((await tasks.getSubtasks(t.id)).map((s) => s.title), ['b', 'a']);
    });
  });

  group('TaskService', () {
    test('delete can be undone with subtasks', () async {
      final t = await tasks.create(workspaceId: ws, title: 'Keep me', tags: ['x']);
      await tasks.addSubtask(t.id, 'child');
      final snapshot = await service.delete(t.id);
      expect(await tasks.get(t.id), isNull);
      await service.undoDelete(snapshot!);
      final restored = await tasks.get(t.id);
      expect(restored!.title, 'Keep me');
      expect(restored.subtaskCount, 1);
    });

    test('completing a repeating task schedules the next one', () async {
      final t = await tasks.create(
        workspaceId: ws,
        title: 'Standup',
        dueDate: '2026-11-04',
        recurrence: Recurrence.weekdays,
      );
      await tasks.addSubtask(t.id, 'notes', isDone: true);
      final next = await service.toggleComplete(t);
      expect(next!.dueDate, '2026-11-05');
      expect(next.recurrence, Recurrence.weekdays);
      final nextSubtasks = await tasks.getSubtasks(next.id);
      expect(nextSubtasks.single.isDone, isFalse);
      final old = await tasks.get(t.id);
      expect(old!.isCompleted, isTrue);
      expect(old.recurrence, isNull);
    });

    test('an overdue repeating task rolls forward to today or later', () async {
      final t = await tasks.create(workspaceId: ws, title: 'Water plants', dueDate: '2026-10-01', recurrence: Recurrence.daily);
      final next = await service.toggleComplete(t);
      expect(next!.dueDate, '2026-11-04');
    });
  });

  group('ProjectRepository', () {
    test('validates date order', () async {
      expect(
        () => projects.create(workspaceId: ws, name: 'P', startDate: '2026-11-10', dueDate: '2026-11-01'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('counts linked tasks and unlinks them on delete', () async {
      final p = await projects.create(workspaceId: ws, name: 'Launch');
      final t = await tasks.create(workspaceId: ws, title: 'a', projectId: p.id);
      await tasks.create(workspaceId: ws, title: 'b', projectId: p.id, status: TaskStatus.completed);
      final listed = (await projects.watchByWorkspace(ws).first).single;
      expect(listed.taskCount, 2);
      expect(listed.completedTaskCount, 1);
      expect(listed.progress, 0.5);

      await projects.delete(p.id);
      expect((await tasks.get(t.id))!.projectId, isNull);
    });
  });

  test('task JSON uses the web field names', () async {
    final t = await tasks.create(workspaceId: ws, title: 'x', dueDate: '2026-11-04');
    final json = t.toJson();
    expect(json['order'], isA<double>());
    expect(json['status'], 'todo');
    expect(json.containsKey('subtaskCount'), isFalse);
    // Keep the import of drift's Value used for clarity in other tests.
    expect(const Value(1).present, isTrue);
  });

  group('widget actions', () {
    test('tick, start and reschedule are saved', () async {
      final t = await tasks.create(workspaceId: ws, title: 'From widget', dueDate: '2026-11-01');
      expect(await applyWidgetTaskUpdate(tasks, service, UpdateTaskAction(taskId: t.id, dueDate: '2026-11-04')), isTrue);
      expect((await tasks.get(t.id))!.dueDate, '2026-11-04');

      await applyWidgetTaskUpdate(tasks, service, UpdateTaskAction(taskId: t.id, status: TaskStatus.inProgress));
      expect((await tasks.get(t.id))!.status, TaskStatus.inProgress);

      await applyWidgetTaskUpdate(tasks, service, UpdateTaskAction(taskId: t.id, status: TaskStatus.completed));
      final done = await tasks.get(t.id);
      expect(done!.isCompleted, isTrue);
      expect(done.completedAt, isNotNull);
    });

    test('completing a repeating task on a widget schedules the next one', () async {
      final t = await tasks.create(workspaceId: ws, title: 'Daily', dueDate: '2026-11-04', recurrence: Recurrence.daily);
      await applyWidgetTaskUpdate(tasks, service, UpdateTaskAction(taskId: t.id, status: TaskStatus.completed));
      final all = await tasks.watchByWorkspace(ws).first;
      expect(all.where((x) => x.title == 'Daily' && x.isOpen).single.dueDate, '2026-11-05');
    });

    test('a task deleted in the app is skipped', () async {
      expect(await applyWidgetTaskUpdate(tasks, service, const UpdateTaskAction(taskId: 'gone', status: TaskStatus.completed)), isTrue);
    });
  });
}
