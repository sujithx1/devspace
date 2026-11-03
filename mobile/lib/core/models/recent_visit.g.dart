// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recent_visit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RecentVisit _$RecentVisitFromJson(Map<String, dynamic> json) => _RecentVisit(
  id: json['id'] as String,
  workspaceId: json['workspaceId'] as String,
  entityType: $enumDecode(_$EntityTypeEnumMap, json['entityType']),
  entityId: json['entityId'] as String,
  visitedAt: const EpochMillisConverter().fromJson(
    (json['visitedAt'] as num).toInt(),
  ),
);

Map<String, dynamic> _$RecentVisitToJson(_RecentVisit instance) =>
    <String, dynamic>{
      'id': instance.id,
      'workspaceId': instance.workspaceId,
      'entityType': _$EntityTypeEnumMap[instance.entityType]!,
      'entityId': instance.entityId,
      'visitedAt': const EpochMillisConverter().toJson(instance.visitedAt),
    };

const _$EntityTypeEnumMap = {
  EntityType.note: 'note',
  EntityType.doc: 'doc',
  EntityType.task: 'task',
  EntityType.project: 'project',
  EntityType.drawing: 'drawing',
};
