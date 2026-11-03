import '../../core/models/workspace.dart';

/// One-line description of what's in a workspace, e.g. "3 open tasks · 2 notes".
String workspaceSummary(WorkspaceStats? stats) {
  if (stats == null) return ' ';
  if (stats.isEmpty) return 'Empty';
  String plural(int n, String word) => '$n $word${n == 1 ? '' : 's'}';
  final parts = [
    if (stats.openTasks > 0) plural(stats.openTasks, 'open task'),
    if (stats.openTasks == 0 && stats.tasks > 0) plural(stats.tasks, 'completed task'),
    if (stats.projects > 0) plural(stats.projects, 'project'),
    if (stats.notes > 0) plural(stats.notes, 'note'),
    if (stats.docs > 0) plural(stats.docs, 'doc'),
    if (stats.drawings > 0) plural(stats.drawings, 'drawing'),
    if (stats.folders > 0) plural(stats.folders, 'folder'),
  ];
  return parts.take(3).join(' · ');
}
