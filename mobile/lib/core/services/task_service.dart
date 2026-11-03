import '../models/enums.dart';
import '../models/task.dart';
import '../repositories/recent_repository.dart';
import '../repositories/task_repository.dart';
import '../utils/dates.dart';

/// Task rules that go beyond a single write: completing repeating tasks,
/// undoable deletes and recently-opened tracking.
class TaskService {
  TaskService(this._tasks, this._recents, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final TaskRepository _tasks;
  final RecentRepository _recents;
  final DateTime Function() _clock;

  /// Moves [task] to [status]. Completing a repeating task also schedules its
  /// next occurrence, which is returned.
  Future<Task?> setStatus(Task task, TaskStatus status) async {
    if (task.status == status) return null;
    final repeats = status == TaskStatus.completed && task.recurrence != null;
    // The finished occurrence stops repeating; the next one carries the rule.
    await _tasks.update(task.copyWith(status: status, recurrence: repeats ? null : task.recurrence));
    return repeats ? _scheduleNext(task) : null;
  }

  Future<Task?> toggleComplete(Task task) =>
      setStatus(task, task.isCompleted ? TaskStatus.todo : TaskStatus.completed);

  /// Creates the next occurrence of a repeating task, on or after today, with
  /// the same details and its subtasks unchecked.
  Future<Task> _scheduleNext(Task task) async {
    final today = Dates.dateOnly(_clock());
    var next = Dates.nextOccurrence(task.recurrence!, task.dueDay ?? today);
    while (next.isBefore(today)) {
      next = Dates.nextOccurrence(task.recurrence!, next);
    }
    final created = await _tasks.create(
      workspaceId: task.workspaceId,
      title: task.title,
      description: task.description,
      priority: task.priority,
      dueDate: Dates.toIso(next),
      dueTime: task.dueTime,
      recurrence: task.recurrence,
      tags: task.tags,
      projectId: task.projectId,
    );
    for (final s in await _tasks.getSubtasks(task.id)) {
      await _tasks.addSubtask(created.id, s.title);
    }
    return created;
  }

  /// Deletes [taskId] and returns what's needed to undo it.
  Future<TaskSnapshot?> delete(String taskId) async {
    final snapshot = await _tasks.snapshot(taskId);
    if (snapshot != null) await _tasks.delete(taskId);
    return snapshot;
  }

  Future<void> undoDelete(TaskSnapshot snapshot) => _tasks.restore(snapshot);

  Future<void> markOpened(Task task) =>
      _recents.touch(workspaceId: task.workspaceId, type: EntityType.task, entityId: task.id);
}
