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
        task('far', due: '2026-12-25'), // beyond two weeks
        task('undated'),
        task('doing', status: TaskStatus.inProgress),
        task('done-today', status: TaskStatus.completed, completedAt: DateTime(2026, 11, 4, 8)),
        task('done-long-ago', status: TaskStatus.completed, completedAt: DateTime(2026, 10, 1)),
      ],
      projects: [project],
      now: now,
    );
    final ids = [for (final t in snapshot['tasks'] as List) (t as Map)['id']];

    test('keeps what the widgets need and nothing more', () {
      expect(ids, containsAll(['overdue', 'today', 'soon', 'doing', 'done-today']));
      expect(ids, isNot(contains('far')));
      expect(ids, isNot(contains('undated')));
      expect(ids, isNot(contains('done-long-ago')));
    });

    test('uses the shape the Swift models decode', () {
      expect(snapshot['version'], widgetSnapshotVersion);
      expect(snapshot['workspace'], {'name': 'Personal', 'icon': '🚀'});
      final today = (snapshot['tasks'] as List).cast<Map>().firstWhere((t) => t['id'] == 'today');
      expect(today['due'], '2026-11-04');
      expect(today['priority'], 'medium');
      expect(today['status'], 'todo');
      expect(today['project'], 'Launch');
      expect(today['projectColor'], 'violet');
      final p = (snapshot['projects'] as List).single as Map;
      expect(p['progress'], 0.25);
      expect(p['openTasks'], 3);
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

  test('WidgetAction parses queued JSON', () {
    expect(WidgetAction.fromJson({'type': 'complete', 'taskId': 'a', 'completed': false}), isA<CompleteTaskAction>());
    expect((WidgetAction.fromJson({'type': 'complete', 'taskId': 'a'}) as CompleteTaskAction).completed, isTrue);
    expect(WidgetAction.fromJson({'type': 'url', 'url': 'devspace://capture/task'}), isA<OpenUrlAction>());
    expect(WidgetAction.fromJson({'type': 'mystery'}), isNull);
  });
}
