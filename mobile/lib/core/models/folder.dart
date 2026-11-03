import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';
import 'json_converters.dart';

part 'folder.freezed.dart';
part 'folder.g.dart';

/// Groups notes, docs or drawings inside a workspace.
@freezed
abstract class Folder with _$Folder {
  const factory Folder({
    required String id,
    required String workspaceId,
    required FolderKind kind,
    required String name,
    @EpochMillisConverter() required DateTime createdAt,
    @EpochMillisConverter() required DateTime updatedAt,
  }) = _Folder;

  factory Folder.fromJson(Map<String, dynamic> json) => _$FolderFromJson(json);
}
