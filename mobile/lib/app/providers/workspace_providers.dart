import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/enums.dart';
import '../../core/models/folder.dart';
import '../../core/models/workspace.dart';
import '../../core/repositories/preferences_repository.dart';
import 'core_providers.dart';

final workspacesProvider = StreamProvider<List<Workspace>>(
  (ref) => ref.watch(workspaceRepositoryProvider).watchAll(),
);

final activeWorkspaceIdProvider = StreamProvider<String?>(
  (ref) => ref.watch(preferencesRepositoryProvider).watch(PreferenceKey.activeWorkspaceId),
);

/// The workspace everything else is scoped to. Falls back to the oldest
/// workspace when the stored id is missing or stale.
final activeWorkspaceProvider = Provider<Workspace?>((ref) {
  final workspaces = ref.watch(workspacesProvider).value ?? const [];
  final id = ref.watch(activeWorkspaceIdProvider).value;
  return workspaces.firstWhereOrNull((w) => w.id == id) ?? workspaces.firstOrNull;
});

final workspaceProvider = Provider.family<Workspace?, String>(
  (ref, id) => ref.watch(workspacesProvider).value?.firstWhereOrNull((w) => w.id == id),
);

final workspaceStatsProvider = StreamProvider.family<WorkspaceStats, String>(
  (ref, id) => ref.watch(workspaceRepositoryProvider).watchStats(id),
);

final foldersProvider = StreamProvider.family<List<Folder>, ({String workspaceId, FolderKind kind})>(
  (ref, args) => ref.watch(folderRepositoryProvider).watchByWorkspace(args.workspaceId, kind: args.kind),
);
