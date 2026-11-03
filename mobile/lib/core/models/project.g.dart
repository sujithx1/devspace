// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Project _$ProjectFromJson(Map<String, dynamic> json) => _Project(
  id: json['id'] as String,
  workspaceId: json['workspaceId'] as String,
  name: json['name'] as String,
  description: json['description'] as String? ?? '',
  status:
      $enumDecodeNullable(_$ProjectStatusEnumMap, json['status']) ??
      ProjectStatus.planning,
  priority:
      $enumDecodeNullable(_$PriorityEnumMap, json['priority']) ??
      Priority.medium,
  color:
      $enumDecodeNullable(_$ProjectColorEnumMap, json['color']) ??
      ProjectColor.indigo,
  startDate: json['startDate'] as String?,
  dueDate: json['dueDate'] as String?,
  createdAt: const EpochMillisConverter().fromJson(
    (json['createdAt'] as num).toInt(),
  ),
  updatedAt: const EpochMillisConverter().fromJson(
    (json['updatedAt'] as num).toInt(),
  ),
);

Map<String, dynamic> _$ProjectToJson(_Project instance) => <String, dynamic>{
  'id': instance.id,
  'workspaceId': instance.workspaceId,
  'name': instance.name,
  'description': instance.description,
  'status': _$ProjectStatusEnumMap[instance.status]!,
  'priority': _$PriorityEnumMap[instance.priority]!,
  'color': _$ProjectColorEnumMap[instance.color]!,
  'startDate': instance.startDate,
  'dueDate': instance.dueDate,
  'createdAt': const EpochMillisConverter().toJson(instance.createdAt),
  'updatedAt': const EpochMillisConverter().toJson(instance.updatedAt),
};

const _$ProjectStatusEnumMap = {
  ProjectStatus.planning: 'planning',
  ProjectStatus.active: 'active',
  ProjectStatus.onHold: 'on_hold',
  ProjectStatus.completed: 'completed',
};

const _$PriorityEnumMap = {
  Priority.low: 'low',
  Priority.medium: 'medium',
  Priority.high: 'high',
  Priority.urgent: 'urgent',
};

const _$ProjectColorEnumMap = {
  ProjectColor.indigo: 'indigo',
  ProjectColor.emerald: 'emerald',
  ProjectColor.amber: 'amber',
  ProjectColor.rose: 'rose',
  ProjectColor.sky: 'sky',
  ProjectColor.violet: 'violet',
  ProjectColor.zinc: 'zinc',
};
