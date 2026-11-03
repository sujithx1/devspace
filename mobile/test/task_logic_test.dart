import 'package:devspace/core/models/enums.dart';
import 'package:devspace/core/models/task.dart';
import 'package:devspace/core/utils/dates.dart';
import 'package:devspace/features/tasks/task_logic.dart';
import 'package:flutter_test/flutter_test.dart';

final today = DateTime(2026, 11, 4); // Wednesday
var _seq = 0;

Task task(
  String title, {
  String? due,
  String? time,
  TaskStatus status = TaskStatus.todo,
  Priority priority = Priority.medium,
  DateTime? completedAt,
  List<String> tags = const [],
  String? projectId,
}) {
  _seq++;
  return Task(
    id: 't$_seq',
    workspaceId: 'w',
    title: title,
    dueDate: due,
    dueTime: time,
    status: status,
    priority: priority,
    completedAt: completedAt,
    tags: tags,
    projectId: projectId,
    sortOrder: _seq.toDouble(),
    createdAt: DateTime(2026, 11, 1).add(Duration(minutes: _seq)),
    updatedAt: DateTime(2026, 11, 1),
  );
}

void main() {
  group('Dates', () {
    test('iso round trip and day math', () {
      expect(Dates.toIso(DateTime(2026, 3, 7)), '2026-03-07');
      expect(Dates.parseIso('2026-03-07'), DateTime(2026, 3, 7));
      expect(Dates.daysBetween(today, DateTime(2026, 11, 6)), 2);
      expect(Dates.startOfWeek(today), DateTime(2026, 11, 2));
    });

    test('nextOccurrence', () {
      expect(Dates.nextOccurrence(Recurrence.daily, today), DateTime(2026, 11, 5));
      expect(Dates.nextOccurrence(Recurrence.weekdays, DateTime(2026, 11, 6)), DateTime(2026, 11, 9)); // Fri → Mon
      expect(Dates.nextOccurrence(Recurrence.weekly, today), DateTime(2026, 11, 11));
      expect(Dates.nextOccurrence(Recurrence.monthly, DateTime(2027, 1, 31)), DateTime(2027, 2, 28));
      expect(Dates.nextOccurrence(Recurrence.yearly, DateTime(2028, 2, 29)), DateTime(2029, 2, 28));
    });
  });

  group('buildSections', () {
    final overdue = task('late', due: '2026-11-02');
    final dueToday = task('today', due: '2026-11-04');
    final tomorrow = task('tomorrow', due: '2026-11-05');
    final later = task('later', due: '2026-11-20');
    final undated = task('someday');
    final doing = task('doing', status: TaskStatus.inProgress);
    final done = task('done', due: '2026-11-04', status: TaskStatus.completed, completedAt: DateTime(2026, 11, 4, 9));
    final all = [overdue, dueToday, tomorrow, later, undated, doing, done];

    test('today shows overdue then due today, open only', () {
      final s = buildSections(all, TaskView.today, today);
      expect(s.map((e) => e.title), ['Overdue', 'Today']);
      expect(s[0].tasks, [overdue]);
      expect(s[0].isWarning, isTrue);
      expect(s[1].tasks, [dueToday]);
    });

    test('upcoming groups future tasks by day', () {
      final s = buildSections(all, TaskView.upcoming, today);
      expect(s.map((e) => e.title), ['Tomorrow', 'Fri, Nov 20']);
    });

    test('all splits open tasks by status', () {
      final s = buildSections(all, TaskView.all, today);
      expect(s.map((e) => e.title), ['In Progress', 'To Do']);
      expect(s[1].tasks.first, overdue); // earliest due first, undated last
      expect(s[1].tasks.last, undated);
    });

    test('completed groups by completion day', () {
      final s = buildSections(all, TaskView.completed, today);
      expect(s.single.title, 'Today');
      expect(s.single.tasks, [done]);
    });
  });

  group('filter and sort', () {
    test('filters by query, priority, project and tag', () {
      final a = task('Fix login bug', priority: Priority.urgent, tags: ['auth'], projectId: 'p1');
      final b = task('Write docs', priority: Priority.low);
      expect(const TaskFilter(query: 'login').matches(a), isTrue);
      expect(const TaskFilter(query: 'AUTH').matches(a), isTrue);
      expect(const TaskFilter(query: 'login').matches(b), isFalse);
      expect(const TaskFilter(priorities: {Priority.low}).matches(a), isFalse);
      expect(const TaskFilter(projectId: 'p1').matches(a), isTrue);
      expect(const TaskFilter(projectId: TaskFilter.noProject).matches(b), isTrue);
      expect(const TaskFilter(tag: 'Auth').matches(a), isTrue);
    });

    test('priority sort puts urgent first', () {
      final low = task('low', priority: Priority.low);
      final urgent = task('urgent', priority: Priority.urgent);
      expect(sortTasks([low, urgent], TaskSort.priority), [urgent, low]);
    });

    test('timed tasks sort within the day', () {
      final late = task('late', due: '2026-11-04', time: '17:00');
      final early = task('early', due: '2026-11-04', time: '09:00');
      expect(sortTasks([late, early], TaskSort.dueDate), [early, late]);
    });
  });

  group('labels', () {
    test('dueLabel', () {
      expect(dueLabel(task('a', due: '2026-11-04'), today), 'Today');
      expect(dueLabel(task('a', due: '2026-11-05', time: '09:30'), today), 'Tomorrow, 9:30\u202fAM');
      expect(dueLabel(task('a', due: '2026-11-07'), today), 'Sat');
      expect(dueLabel(task('a', due: '2027-01-02'), today), 'Jan 2, 2027');
    });
  });

  test('TaskStats', () {
    final tasks = [
      task('late', due: '2026-11-01'),
      task('today', due: '2026-11-04'),
      task('done today', status: TaskStatus.completed, completedAt: DateTime(2026, 11, 4, 8)),
      task('done monday', status: TaskStatus.completed, completedAt: DateTime(2026, 11, 2, 8)),
      task('done last week', status: TaskStatus.completed, completedAt: DateTime(2026, 10, 30)),
    ];
    final stats = TaskStats.from(tasks, today);
    expect(stats.open, 2);
    expect(stats.overdue, 1);
    expect(stats.dueToday, 1);
    expect(stats.completedToday, 1);
    expect(stats.completedThisWeek, 2);
    expect(stats.dailyCompletions, [1, 0, 1, 0, 0, 0, 0]);
    expect(stats.todayProgress, closeTo(1 / 3, 0.001));
  });
}
