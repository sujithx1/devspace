import 'package:freezed_annotation/freezed_annotation.dart';

import '../utils/dates.dart';
import 'enums.dart';
import 'json_converters.dart';

part 'project.freezed.dart';
part 'project.g.dart';

@freezed
abstract class Project with _$Project {
  const factory Project({
    required String id,
    required String workspaceId,
    required String name,
    @Default('') String description,
    @Default(ProjectStatus.planning) ProjectStatus status,
    @Default(Priority.medium) Priority priority,
    @Default(ProjectColor.indigo) ProjectColor color,
    String? startDate,
    String? dueDate,
    @EpochMillisConverter() required DateTime createdAt,
    @EpochMillisConverter() required DateTime updatedAt,

    /// Derived from linked tasks when read from storage; not persisted.
    @JsonKey(includeFromJson: false, includeToJson: false) @Default(0) int taskCount,
    @JsonKey(includeFromJson: false, includeToJson: false) @Default(0) int completedTaskCount,
  }) = _Project;

  const Project._();

  factory Project.fromJson(Map<String, dynamic> json) => _$ProjectFromJson(json);

  /// Share of linked tasks completed, 0–1. Completed projects count as done.
  double get progress {
    if (status == ProjectStatus.completed) return 1;
    if (taskCount == 0) return 0;
    return completedTaskCount / taskCount;
  }

  int get openTaskCount => taskCount - completedTaskCount;

  DateTime? get dueDay => dueDate == null ? null : Dates.parseIso(dueDate!);

  bool get isActive => status == ProjectStatus.active || status == ProjectStatus.planning;
}
