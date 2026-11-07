import '../../core/models/enums.dart';
import '../../core/models/project.dart';
import '../../core/models/task.dart';
import '../../core/models/workspace.dart';
import '../../core/utils/dates.dart';
import '../tasks/task_logic.dart';

/// Version of the JSON the widgets read. Bump with any breaking change and
/// update `ios/Shared/WidgetModels.swift`.
const widgetSnapshotVersion = 2;

/// Builds the data the Home Screen widgets render, for the active workspace.
///
/// It holds raw dates rather than pre-computed "today" lists so the widgets
/// stay correct after midnight without the app running:
///
/// - every open task (most pressing first, capped), so any list or project
///   can be shown and acted on;
/// - tasks completed in the last 12 weeks, for streaks and the activity grid;
/// - every project that isn't completed, with its progress.
Map<String, dynamic> buildWidgetSnapshot({
  required Workspace? workspace,
  required List<Task> tasks,
  required List<Project> projects,
  required DateTime now,
  int maxOpenTasks = 200,
  int maxCompletedTasks = 400,
}) {
  final today = Dates.dateOnly(now);
  final completedSince = Dates.addDays(today, -7 * 12);
  final projectsById = {for (final p in projects) p.id: p};

  final open = sortTasks(tasks.where((t) => t.isOpen), TaskSort.smart).take(maxOpenTasks);

  final completed =
      (tasks.where((t) => t.isCompleted && t.completedAt != null && !t.completedAt!.isBefore(completedSince)).toList()
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
      'projectId': project?.id,
      'project': project?.name,
      'projectColor': project?.color.wire,
      'repeats': t.recurrence != null,
    };
  }

  // Due ones first (soonest first), then by name.
  final activeProjects = projects.where((p) => p.status != ProjectStatus.completed).toList()
    ..sort((a, b) {
      final byDue = (a.dueDate ?? '9999').compareTo(b.dueDate ?? '9999');
      return byDue != 0 ? byDue : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

  return {
    'version': widgetSnapshotVersion,
    'generatedAt': now.millisecondsSinceEpoch,
    'workspace': workspace == null ? null : {'name': workspace.name, 'icon': workspace.icon},
    'tasks': [for (final t in [...open, ...completed]) taskJson(t)],
    'projects': [
      for (final p in activeProjects)
        {
          'id': p.id,
          'name': p.name,
          'due': p.dueDate,
          'color': p.color.wire,
          'status': p.status.wire,
          'priority': p.priority.wire,
          'progress': p.progress,
          'openTasks': p.openTaskCount,
          'totalTasks': p.taskCount,
        },
    ],
  };
}
