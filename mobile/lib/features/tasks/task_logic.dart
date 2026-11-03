import 'package:intl/intl.dart';

import '../../core/models/enums.dart';
import '../../core/models/project.dart';
import '../../core/models/task.dart';
import '../../core/utils/dates.dart';

/// Pure task logic: views, filtering, sorting, grouping and statistics.
/// Nothing here touches storage or widgets, so it is unit-tested directly.

enum TaskView {
  today('Today'),
  upcoming('Upcoming'),
  all('All'),
  completed('Done');

  const TaskView(this.label);
  final String label;
}

enum TaskSort {
  smart('Smart'),
  dueDate('Due Date'),
  priority('Priority'),
  created('Recently Added'),
  title('Title');

  const TaskSort(this.label);
  final String label;
}

/// Search text plus optional filters. Empty means "match everything".
class TaskFilter {
  const TaskFilter({this.query = '', this.priorities = const {}, this.projectId, this.tag});

  /// Matches tasks without a project.
  static const noProject = '__none__';

  final String query;
  final Set<Priority> priorities;
  final String? projectId;
  final String? tag;

  bool get isActive => priorities.isNotEmpty || projectId != null || tag != null;
  int get activeCount => (priorities.isNotEmpty ? 1 : 0) + (projectId != null ? 1 : 0) + (tag != null ? 1 : 0);

  TaskFilter copyWith({String? query, Set<Priority>? priorities, String? Function()? projectId, String? Function()? tag}) =>
      TaskFilter(
        query: query ?? this.query,
        priorities: priorities ?? this.priorities,
        projectId: projectId == null ? this.projectId : projectId(),
        tag: tag == null ? this.tag : tag(),
      );

  bool matches(Task task, {Map<String, Project> projects = const {}}) {
    if (priorities.isNotEmpty && !priorities.contains(task.priority)) return false;
    if (projectId == noProject && task.projectId != null) return false;
    if (projectId != null && projectId != noProject && task.projectId != projectId) return false;
    if (tag != null && !task.tags.any((t) => t.toLowerCase() == tag!.toLowerCase())) return false;
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return task.title.toLowerCase().contains(q) ||
        task.description.toLowerCase().contains(q) ||
        task.tags.any((t) => t.toLowerCase().contains(q)) ||
        (projects[task.projectId]?.name.toLowerCase().contains(q) ?? false);
  }
}

class TaskSection {
  const TaskSection({required this.title, required this.tasks, this.isWarning = false});

  final String title;
  final List<Task> tasks;

  /// Rendered in the warning colour (e.g. Overdue).
  final bool isWarning;
}

/// Orders tasks. "Smart" puts in-progress work first, then by due date
/// (undated last), then priority, then the order they were added.
int compareTasks(Task a, Task b, TaskSort sort) {
  int byDue() {
    final ad = a.dueAt, bd = b.dueAt;
    if (ad == null && bd == null) return 0;
    if (ad == null) return 1;
    if (bd == null) return -1;
    return ad.compareTo(bd);
  }

  int byPriority() => b.priority.rank.compareTo(a.priority.rank);
  int byOrder() => a.sortOrder.compareTo(b.sortOrder);

  final int result = switch (sort) {
    TaskSort.smart => _firstNonZero([
      () => (b.status == TaskStatus.inProgress ? 1 : 0).compareTo(a.status == TaskStatus.inProgress ? 1 : 0),
      byDue,
      byPriority,
      byOrder,
    ]),
    TaskSort.dueDate => _firstNonZero([byDue, byPriority, byOrder]),
    TaskSort.priority => _firstNonZero([byPriority, byDue, byOrder]),
    TaskSort.created => b.createdAt.compareTo(a.createdAt),
    TaskSort.title => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
  };
  return result;
}

int _firstNonZero(List<int Function()> comparisons) {
  for (final c in comparisons) {
    final r = c();
    if (r != 0) return r;
  }
  return 0;
}

List<Task> sortTasks(Iterable<Task> tasks, TaskSort sort) => tasks.toList()..sort((a, b) => compareTasks(a, b, sort));

/// Splits [tasks] into the sections shown for [view].
List<TaskSection> buildSections(
  List<Task> tasks,
  TaskView view,
  DateTime today, {
  TaskFilter filter = const TaskFilter(),
  TaskSort sort = TaskSort.smart,
  Map<String, Project> projects = const {},
}) {
  final day = Dates.dateOnly(today);
  final visible = tasks.where((t) => filter.matches(t, projects: projects));
  List<Task> sorted(Iterable<Task> list) => sortTasks(list, sort);

  switch (view) {
    case TaskView.today:
      final open = visible.where((t) => t.isOpen);
      return _nonEmpty([
        TaskSection(title: 'Overdue', tasks: sorted(open.where((t) => t.isOverdue(day))), isWarning: true),
        TaskSection(title: 'Today', tasks: sorted(open.where((t) => t.isDueOn(day)))),
      ]);

    case TaskView.upcoming:
      final future = visible.where((t) => t.isOpen && t.dueDay != null && t.dueDay!.isAfter(day));
      final byDay = <DateTime, List<Task>>{};
      for (final t in future) {
        byDay.putIfAbsent(t.dueDay!, () => []).add(t);
      }
      final days = byDay.keys.toList()..sort();
      return [for (final d in days) TaskSection(title: dayHeading(d, day), tasks: sorted(byDay[d]!))];

    case TaskView.all:
      final open = visible.where((t) => t.isOpen);
      return _nonEmpty([
        TaskSection(title: 'In Progress', tasks: sorted(open.where((t) => t.status == TaskStatus.inProgress))),
        TaskSection(title: 'To Do', tasks: sorted(open.where((t) => t.status == TaskStatus.todo))),
      ]);

    case TaskView.completed:
      final done = visible.where((t) => t.isCompleted).toList()
        ..sort((a, b) => (b.completedAt ?? b.updatedAt).compareTo(a.completedAt ?? a.updatedAt));
      final byDay = <DateTime, List<Task>>{};
      for (final t in done) {
        byDay.putIfAbsent(Dates.dateOnly(t.completedAt ?? t.updatedAt), () => []).add(t);
      }
      final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
      return [for (final d in days) TaskSection(title: dayHeading(d, day), tasks: byDay[d]!)];
  }
}

List<TaskSection> _nonEmpty(List<TaskSection> sections) => sections.where((s) => s.tasks.isNotEmpty).toList();

/// Groups open tasks by status for the board, in board column order.
Map<TaskStatus, List<Task>> boardColumns(
  List<Task> tasks, {
  TaskFilter filter = const TaskFilter(),
  TaskSort sort = TaskSort.smart,
  Map<String, Project> projects = const {},
}) {
  final visible = tasks.where((t) => filter.matches(t, projects: projects));
  return {
    for (final status in TaskStatus.values)
      status: status == TaskStatus.completed
          ? (visible.where((t) => t.status == status).toList()
              ..sort((a, b) => (b.completedAt ?? b.updatedAt).compareTo(a.completedAt ?? a.updatedAt)))
          : sortTasks(visible.where((t) => t.status == status), sort),
  };
}

/// "Today", "Tomorrow", "Yesterday", a weekday within the coming week, or a date.
String dayHeading(DateTime day, DateTime today) {
  final diff = Dates.daysBetween(today, day);
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Tomorrow';
  if (diff == -1) return 'Yesterday';
  if (diff > 1 && diff < 7) return DateFormat('EEEE').format(day);
  if (day.year == today.year) return DateFormat('EEE, MMM d').format(day);
  return DateFormat('MMM d, y').format(day);
}

/// Compact due label for rows: "Today", "Tomorrow 9:30 AM", "Mon", "Nov 12".
String dueLabel(Task task, DateTime today) {
  final day = task.dueDay;
  if (day == null) return '';
  final diff = Dates.daysBetween(today, day);
  final String date;
  if (diff == 0) {
    date = 'Today';
  } else if (diff == 1) {
    date = 'Tomorrow';
  } else if (diff == -1) {
    date = 'Yesterday';
  } else if (diff > 1 && diff < 7) {
    date = DateFormat('EEE').format(day);
  } else if (day.year == today.year) {
    date = DateFormat('MMM d').format(day);
  } else {
    date = DateFormat('MMM d, y').format(day);
  }
  final at = task.dueAt;
  return task.dueTime == null || at == null ? date : '$date, ${DateFormat.jm().format(at)}';
}

/// Productivity numbers for Home (and later, the widgets).
class TaskStats {
  const TaskStats({
    required this.open,
    required this.dueToday,
    required this.overdue,
    required this.completedToday,
    required this.completedThisWeek,
    required this.dailyCompletions,
  });

  factory TaskStats.from(List<Task> tasks, DateTime today) {
    final day = Dates.dateOnly(today);
    final weekStart = Dates.startOfWeek(day);
    final daily = List<int>.filled(7, 0);
    var completedToday = 0;
    var open = 0, dueToday = 0, overdue = 0;
    for (final t in tasks) {
      if (t.isOpen) {
        open++;
        if (t.isOverdue(day)) overdue++;
        if (t.isDueOn(day)) dueToday++;
        continue;
      }
      final done = t.completedAt;
      if (done == null) continue;
      final doneDay = Dates.dateOnly(done);
      if (doneDay == day) completedToday++;
      final index = Dates.daysBetween(weekStart, doneDay);
      if (index >= 0 && index < 7) daily[index]++;
    }
    return TaskStats(
      open: open,
      dueToday: dueToday,
      overdue: overdue,
      completedToday: completedToday,
      completedThisWeek: daily.fold(0, (a, b) => a + b),
      dailyCompletions: daily,
    );
  }

  final int open;
  final int dueToday;
  final int overdue;
  final int completedToday;
  final int completedThisWeek;

  /// Completions per day this week, Monday first.
  final List<int> dailyCompletions;

  /// Share of today's work that's done: completed today vs. completed today
  /// plus still due today or overdue. 0–1; 0 when there's nothing.
  double get todayProgress {
    final total = completedToday + dueToday + overdue;
    return total == 0 ? 0 : completedToday / total;
  }
}
