import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/repositories/folder_repository.dart';
import '../../core/repositories/preferences_repository.dart';
import '../../core/repositories/project_repository.dart';
import '../../core/repositories/recent_repository.dart';
import '../../core/repositories/task_repository.dart';
import '../../core/repositories/workspace_repository.dart';
import '../../core/services/task_service.dart';
import '../../core/services/workspace_service.dart';

/// Composition root. Swap these implementations (e.g. for a sync-aware or
/// HTTP-backed repository) without touching any UI.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final workspaceRepositoryProvider = Provider<WorkspaceRepository>(
  (ref) => DriftWorkspaceRepository(ref.watch(appDatabaseProvider)),
);

final folderRepositoryProvider = Provider<FolderRepository>(
  (ref) => DriftFolderRepository(ref.watch(appDatabaseProvider)),
);

final recentRepositoryProvider = Provider<RecentRepository>(
  (ref) => DriftRecentRepository(ref.watch(appDatabaseProvider)),
);

final preferencesRepositoryProvider = Provider<PreferencesRepository>(
  (ref) => DriftPreferencesRepository(ref.watch(appDatabaseProvider)),
);

final workspaceServiceProvider = Provider<WorkspaceService>(
  (ref) => WorkspaceService(ref.watch(workspaceRepositoryProvider), ref.watch(preferencesRepositoryProvider)),
);

final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => DriftTaskRepository(ref.watch(appDatabaseProvider)),
);

final projectRepositoryProvider = Provider<ProjectRepository>(
  (ref) => DriftProjectRepository(ref.watch(appDatabaseProvider)),
);

final taskServiceProvider = Provider<TaskService>(
  (ref) => TaskService(ref.watch(taskRepositoryProvider), ref.watch(recentRepositoryProvider)),
);
