// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Task _$TaskFromJson(Map<String, dynamic> json) => _Task(
  id: json['id'] as String,
  workspaceId: json['workspaceId'] as String,
  projectId: json['projectId'] as String?,
  title: json['title'] as String,
  description: json['description'] as String? ?? '',
  status:
      $enumDecodeNullable(_$TaskStatusEnumMap, json['status']) ??
      TaskStatus.todo,
  priority:
      $enumDecodeNullable(_$PriorityEnumMap, json['priority']) ??
      Priority.medium,
  dueDate: json['dueDate'] as String?,
  dueTime: json['dueTime'] as String?,
  recurrence: $enumDecodeNullable(_$RecurrenceEnumMap, json['recurrence']),
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  sortOrder: (json['order'] as num?)?.toDouble() ?? 0,
  completedAt: const NullableEpochMillisConverter().fromJson(
    (json['completedAt'] as num?)?.toInt(),
  ),
  createdAt: const EpochMillisConverter().fromJson(
    (json['createdAt'] as num).toInt(),
  ),
  updatedAt: const EpochMillisConverter().fromJson(
    (json['updatedAt'] as num).toInt(),
  ),
);

Map<String, dynamic> _$TaskToJson(_Task instance) => <String, dynamic>{
  'id': instance.id,
  'workspaceId': instance.workspaceId,
  'projectId': instance.projectId,
  'title': instance.title,
  'description': instance.description,
  'status': _$TaskStatusEnumMap[instance.status]!,
  'priority': _$PriorityEnumMap[instance.priority]!,
  'dueDate': instance.dueDate,
  'dueTime': instance.dueTime,
  'recurrence': _$RecurrenceEnumMap[instance.recurrence],
  'tags': instance.tags,
  'order': instance.sortOrder,
  'completedAt': const NullableEpochMillisConverter().toJson(
    instance.completedAt,
  ),
  'createdAt': const EpochMillisConverter().toJson(instance.createdAt),
  'updatedAt': const EpochMillisConverter().toJson(instance.updatedAt),
};

const _$TaskStatusEnumMap = {
  TaskStatus.todo: 'todo',
  TaskStatus.inProgress: 'in_progress',
  TaskStatus.completed: 'completed',
};

const _$PriorityEnumMap = {
  Priority.low: 'low',
  Priority.medium: 'medium',
  Priority.high: 'high',
  Priority.urgent: 'urgent',
};

const _$RecurrenceEnumMap = {
  Recurrence.daily: 'daily',
  Recurrence.weekdays: 'weekdays',
  Recurrence.weekly: 'weekly',
  Recurrence.monthly: 'monthly',
  Recurrence.yearly: 'yearly',
};

_Subtask _$SubtaskFromJson(Map<String, dynamic> json) => _Subtask(
  id: json['id'] as String,
  taskId: json['taskId'] as String,
  title: json['title'] as String,
  isDone: json['isDone'] as bool? ?? false,
  sortOrder: (json['sortOrder'] as num?)?.toDouble() ?? 0,
  createdAt: const EpochMillisConverter().fromJson(
    (json['createdAt'] as num).toInt(),
  ),
  updatedAt: const EpochMillisConverter().fromJson(
    (json['updatedAt'] as num).toInt(),
  ),
);

Map<String, dynamic> _$SubtaskToJson(_Subtask instance) => <String, dynamic>{
  'id': instance.id,
  'taskId': instance.taskId,
  'title': instance.title,
  'isDone': instance.isDone,
  'sortOrder': instance.sortOrder,
  'createdAt': const EpochMillisConverter().toJson(instance.createdAt),
  'updatedAt': const EpochMillisConverter().toJson(instance.updatedAt),
};
