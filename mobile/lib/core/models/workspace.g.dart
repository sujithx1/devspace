// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Workspace _$WorkspaceFromJson(Map<String, dynamic> json) => _Workspace(
  id: json['id'] as String,
  name: json['name'] as String,
  icon: json['icon'] as String? ?? '🚀',
  type:
      $enumDecodeNullable(_$WorkspaceTypeEnumMap, json['type']) ??
      WorkspaceType.personal,
  createdAt: const EpochMillisConverter().fromJson(
    (json['createdAt'] as num).toInt(),
  ),
  updatedAt: const EpochMillisConverter().fromJson(
    (json['updatedAt'] as num).toInt(),
  ),
);

Map<String, dynamic> _$WorkspaceToJson(_Workspace instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'icon': instance.icon,
      'type': _$WorkspaceTypeEnumMap[instance.type]!,
      'createdAt': const EpochMillisConverter().toJson(instance.createdAt),
      'updatedAt': const EpochMillisConverter().toJson(instance.updatedAt),
    };

const _$WorkspaceTypeEnumMap = {
  WorkspaceType.personal: 'private',
  WorkspaceType.group: 'group',
};
