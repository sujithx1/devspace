// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'folder.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Folder _$FolderFromJson(Map<String, dynamic> json) => _Folder(
  id: json['id'] as String,
  workspaceId: json['workspaceId'] as String,
  kind: $enumDecode(_$FolderKindEnumMap, json['kind']),
  name: json['name'] as String,
  createdAt: const EpochMillisConverter().fromJson(
    (json['createdAt'] as num).toInt(),
  ),
  updatedAt: const EpochMillisConverter().fromJson(
    (json['updatedAt'] as num).toInt(),
  ),
);

Map<String, dynamic> _$FolderToJson(_Folder instance) => <String, dynamic>{
  'id': instance.id,
  'workspaceId': instance.workspaceId,
  'kind': _$FolderKindEnumMap[instance.kind]!,
  'name': instance.name,
  'createdAt': const EpochMillisConverter().toJson(instance.createdAt),
  'updatedAt': const EpochMillisConverter().toJson(instance.updatedAt),
};

const _$FolderKindEnumMap = {
  FolderKind.note: 'note',
  FolderKind.doc: 'doc',
  FolderKind.drawing: 'drawing',
};
