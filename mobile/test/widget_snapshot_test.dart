import 'package:devspace/core/models/enums.dart';
import 'package:devspace/core/models/project.dart';
import 'package:devspace/core/models/task.dart';
import 'package:devspace/core/models/workspace.dart';
import 'package:devspace/core/services/widget_bridge.dart';
import 'package:devspace/features/widgets/deep_links.dart';
import 'package:devspace/features/widgets/widget_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

final now = DateTime(2026, 11, 4, 10);
final created = DateTime(2026, 10, 1);

Task task(String id, {String? due, TaskStatus status = TaskStatus.todo, DateTime? completedAt, String? projectId}) => Task(
  id: id,
  workspaceId: 'w',
  title: 'Task $id',
  dueDate: due,
  status: status,
  completedAt: completedAt,
  projectId: projectId,
  createdAt: created,
  updatedAt: created,
);

void main() {
  group('buildWidgetSnapshot', () {
    final project = Project(
      id: 'p',
      workspaceId: 'w',
      name: 'Launch',
      color: ProjectColor.violet,
      status: ProjectStatus.active,
      dueDate: '2026-11-20',
      createdAt: created,
      updatedAt: created,
      taskCount: 4,
      completedTaskCount: 1,
    );
    final snapshot = buildWidgetSnapshot(
      workspace: Workspace(id: 'w', name: 'Personal', icon: '🚀', createdAt: created, updatedAt: created),
      tasks: [
        task('overdue', due: '2026-10-30'),
        task('today', due: '2026-11-04', projectId: 'p'),
        task('soon', due: '2026-11-15'),
        task('far', due: '2026-12-25'),
        task('undated'),
        task('doing', status: TaskStatus.inProgress),
        task('done-today', status: TaskStatus.completed, completedAt: DateTime(2026, 11, 4, 8)),
        task('done-long-ago', status: TaskStatus.completed, completedAt: DateTime(2026, 7, 1)),
      ],
      projects: [project],
      now: now,
    );
    final ids = [for (final t in snapshot['tasks'] as List) (t as Map)['id']];

    test('includes every open task and recent completions', () {
      expect(ids, containsAll(['overdue', 'today', 'soon', 'far', 'undated', 'doing', 'done-today']));
      // Completed more than 12 weeks ago.
      expect(ids, isNot(contains('done-long-ago')));
      // Most pressing first: in progress, then by due date.
      expect(ids.first, 'doing');
    });

    test('uses the shape the Swift models decode', () {
      expect(snapshot['version'], widgetSnapshotVersion);
      expect(snapshot['workspace'], {'name': 'Personal', 'icon': '🚀'});
      final today = (snapshot['tasks'] as List).cast<Map>().firstWhere((t) => t['id'] == 'today');
      expect(today['due'], '2026-11-04');
      expect(today['priority'], 'medium');
      expect(today['status'], 'todo');
      expect(today['projectId'], 'p');
      expect(today['project'], 'Launch');
      expect(today['projectColor'], 'violet');
      final p = (snapshot['projects'] as List).single as Map;
      expect(p['progress'], 0.25);
      expect(p['openTasks'], 3);
      expect(p['totalTasks'], 4);
    });
  });

  group('DeepLinks.locationFor', () {
    String? loc(String url) => DeepLinks.locationFor(Uri.parse(url));

    test('accepts known screens and task links', () {
      expect(loc('devspace://open/tasks'), '/tasks');
      expect(loc('devspace://open/tasks/task/abc-123'), '/tasks/task/abc-123');
      expect(loc('devspace://open'), '/home');
    });

    test('rejects anything else', () {
      expect(loc('devspace://open/settings/../../etc'), isNull);
      expect(loc('devspace://open/unknown'), isNull);
      expect(loc('https://open/tasks'), isNull);
      expect(loc('devspace://capture/task'), isNull);
    });
  });

  group('WidgetAction.fromJson', () {
    test('reads task updates from widgets', () {
      final a = WidgetAction.fromJson({'type': 'update', 'taskId': 'a', 'status': 'in_progress', 'due': '2026-11-05'});
      expect(a, isA<UpdateTaskAction>());
      a as UpdateTaskAction;
      expect(a.status, TaskStatus.inProgress);
      expect(a.dueDate, '2026-11-05');
    });

    test('ignores bad fields', () {
      final a = WidgetAction.fromJson({'type': 'update', 'taskId': 'a', 'status': 'nope', 'due': 'tomorrow'}) as UpdateTaskAction;
      expect(a.status, isNull);
      expect(a.dueDate, isNull);
      expect(WidgetAction.fromJson({'type': 'update'}), isNull);
      expect(WidgetAction.fromJson({'type': 'mystery'}), isNull);
    });

    test('still reads version 1 completions', () {
      final done = WidgetAction.fromJson({'type': 'complete', 'taskId': 'a'}) as UpdateTaskAction;
      expect(done.status, TaskStatus.completed);
      final undone = WidgetAction.fromJson({'type': 'complete', 'taskId': 'a', 'completed': false}) as UpdateTaskAction;
      expect(undone.status, TaskStatus.todo);
    });

    test('reads links', () {
      final a = WidgetAction.fromJson({'type': 'url', 'url': 'devspace://capture/task?due=tomorrow'});
      expect((a as OpenUrlAction).uri.queryParameters['due'], 'tomorrow');
    });
  });
}
