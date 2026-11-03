import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';
import 'json_converters.dart';

part 'workspace.freezed.dart';
part 'workspace.g.dart';

@freezed
abstract class Workspace with _$Workspace {
  const factory Workspace({
    required String id,
    required String name,
    @Default('🚀') String icon,
    @Default(WorkspaceType.personal) WorkspaceType type,
    @EpochMillisConverter() required DateTime createdAt,
    @EpochMillisConverter() required DateTime updatedAt,
  }) = _Workspace;

  factory Workspace.fromJson(Map<String, dynamic> json) => _$WorkspaceFromJson(json);
}

/// Item counts shown alongside a workspace.
@freezed
abstract class WorkspaceStats with _$WorkspaceStats {
  const factory WorkspaceStats({
    @Default(0) int tasks,
    @Default(0) int openTasks,
    @Default(0) int projects,
    @Default(0) int notes,
    @Default(0) int docs,
    @Default(0) int drawings,
    @Default(0) int folders,
  }) = _WorkspaceStats;

  const WorkspaceStats._();

  bool get isEmpty => tasks + projects + notes + docs + drawings + folders == 0;
}
