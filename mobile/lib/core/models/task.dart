import 'package:freezed_annotation/freezed_annotation.dart';

import '../utils/dates.dart';
import 'enums.dart';
import 'json_converters.dart';

part 'task.freezed.dart';
part 'task.g.dart';

@freezed
abstract class Task with _$Task {
  const factory Task({
    required String id,
    required String workspaceId,
    String? projectId,
    required String title,
    @Default('') String description,
    @Default(TaskStatus.todo) TaskStatus status,
    @Default(Priority.medium) Priority priority,

    /// `YYYY-MM-DD`, local calendar day.
    String? dueDate,

    /// `HH:mm` on [dueDate].
    String? dueTime,
    Recurrence? recurrence,
    @Default(<String>[]) List<String> tags,
    @JsonKey(name: 'order') @Default(0) double sortOrder,
    @NullableEpochMillisConverter() DateTime? completedAt,
    @EpochMillisConverter() required DateTime createdAt,
    @EpochMillisConverter() required DateTime updatedAt,

    /// Derived from the task's subtasks when read from storage; not persisted.
    @JsonKey(includeFromJson: false, includeToJson: false) @Default(0) int subtaskCount,
    @JsonKey(includeFromJson: false, includeToJson: false) @Default(0) int subtasksDone,
  }) = _Task;

  const Task._();

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);

  bool get isCompleted => status == TaskStatus.completed;
  bool get isOpen => !isCompleted;

  DateTime? get dueDay => dueDate == null ? null : Dates.parseIso(dueDate!);

  /// Due date and time combined, or the start of the due day when untimed.
  DateTime? get dueAt {
    final day = dueDay;
    if (day == null) return null;
    if (dueTime == null) return day;
    final parts = dueTime!.split(':');
    return DateTime(day.year, day.month, day.day, int.parse(parts[0]), int.parse(parts[1]));
  }

  bool isOverdue(DateTime today) => isOpen && dueDay != null && dueDay!.isBefore(Dates.dateOnly(today));
  bool isDueOn(DateTime day) => dueDay != null && Dates.daysBetween(day, dueDay!) == 0;
}

@freezed
abstract class Subtask with _$Subtask {
  const factory Subtask({
    required String id,
    required String taskId,
    required String title,
    @Default(false) bool isDone,
    @Default(0) double sortOrder,
    @EpochMillisConverter() required DateTime createdAt,
    @EpochMillisConverter() required DateTime updatedAt,
  }) = _Subtask;

  factory Subtask.fromJson(Map<String, dynamic> json) => _$SubtaskFromJson(json);
}

/// A task with its subtasks, captured before deletion so it can be restored.
@freezed
abstract class TaskSnapshot with _$TaskSnapshot {
  const factory TaskSnapshot({required Task task, required List<Subtask> subtasks}) = _TaskSnapshot;
}
