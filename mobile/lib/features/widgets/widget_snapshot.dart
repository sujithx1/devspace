import '../../core/models/enums.dart';
import '../../core/models/project.dart';
import '../../core/models/task.dart';
import '../../core/models/workspace.dart';
import '../../core/utils/dates.dart';
import '../tasks/task_logic.dart';

/// Version of the JSON the widgets read. Bump with any breaking change and
/// update `ios/Shared/WidgetModels.swift`.
const widgetSnapshotVersion = 1;

/// Builds the data the Home Screen widgets render, for the active workspace.
///
/// It holds raw dates rather than pre-computed "today" lists so the widgets
/// stay correct after midnight without the app running: open tasks due within
/// two weeks (or overdue, or in progress), tasks completed in the last eight
/// days for the weekly stats, and upcoming project deadlines.
Map<String, dynamic> buildWidgetSnapshot({
  required Workspace? workspace,
  required List<Task> tasks,
  required List<Project> projects,
  required DateTime now,
  int maxOpenTasks = 80,
  int maxCompletedTasks = 150,
}) {
  final today = Dates.dateOnly(now);
  final openHorizon = Dates.addDays(today, 14);
  final completedSince = Dates.addDays(today, -8);
  final projectsById = {for (final p in projects) p.id: p};

  final open = sortTasks(
    tasks.where(
      (t) =>
          t.isOpen &&
          ((t.dueDay != null && !t.dueDay!.isAfter(openHorizon)) || t.status == TaskStatus.inProgress),
    ),
    TaskSort.smart,
  ).take(maxOpenTasks);

  final completed = (tasks.where((t) => t.isCompleted && t.completedAt != null && !t.completedAt!.isBefore(completedSince)).toList()
        ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!)))
      .take(maxCompletedTasks);

  Map<String, dynamic> taskJson(Task t) {
    final project = projectsById[t.projectId];
    return {
      'id': t.id,
      'title': t.title,
      'due': t.dueDate,
      'time': t.dueTime,
      'priority': t.priority.wire,
      'status': t.status.wire,
      'completedAt': t.completedAt?.millisecondsSinceEpoch,
      'project': project?.name,
      'projectColor': project?.color.wire,
      'repeats': t.recurrence != null,
    };
  }

  final projectHorizon = Dates.addDays(today, 30);
  final upcomingProjects =
      projects
          .where((p) => p.status != ProjectStatus.completed && p.dueDay != null && !p.dueDay!.isAfter(projectHorizon))
          .toList()
        ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

  return {
    'version': widgetSnapshotVersion,
    'generatedAt': now.millisecondsSinceEpoch,
    'workspace': workspace == null ? null : {'name': workspace.name, 'icon': workspace.icon},
    'tasks': [for (final t in [...open, ...completed]) taskJson(t)],
    'projects': [
      for (final p in upcomingProjects)
        {
          'id': p.id,
          'name': p.name,
          'due': p.dueDate,
          'color': p.color.wire,
          'status': p.status.wire,
          'priority': p.priority.wire,
          'progress': p.progress,
          'openTasks': p.openTaskCount,
        },
    ],
  };
}
