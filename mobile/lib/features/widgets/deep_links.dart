import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/task_providers.dart';
import '../../app/providers/workspace_providers.dart';
import '../../app/router.dart';
import '../../core/utils/dates.dart';
import '../projects/project_editor_sheet.dart';
import '../tasks/task_editor_sheet.dart';

/// `devspace://` links used by widgets and Shortcuts:
///
/// - `devspace://open/<path>` opens a screen, e.g. `open/tasks/task/<id>`
/// - `devspace://capture/task` and `capture/project` open a "new" sheet;
///   `capture/task?due=today|tomorrow&project=<id>` pre-fills the task
/// - `devspace://project/<id>` opens a project
abstract final class DeepLinks {
  static const scheme = 'devspace';

  static final _openable = RegExp(r'^/(home|tasks|projects|notes|more)(/task/[\w-]+)?$');

  /// The in-app location for an `open` link, or null if it isn't one we know.
  static String? locationFor(Uri uri) {
    if (uri.scheme != scheme || uri.host != 'open') return null;
    final path = uri.path.isEmpty ? '/home' : uri.path;
    return _openable.hasMatch(path) ? path : null;
  }

  static Future<void> handle(Uri uri, Ref ref) async {
    if (uri.scheme != scheme) return;
    // Nothing to open until onboarding has created a workspace.
    if (ref.read(activeWorkspaceProvider) == null) return;
    final router = ref.read(routerProvider);

    switch (uri.host) {
      case 'open':
        final location = locationFor(uri);
        if (location != null) router.go(location);
      case 'capture':
        final kind = uri.pathSegments.firstOrNull;
        router.go(kind == 'project' ? Routes.projects : Routes.tasks);
        await _afterFrame();
        final context = rootNavigatorKey.currentContext;
        if (context == null || !context.mounted) return;
        if (kind == 'project') {
          await showProjectEditor(context);
        } else if (kind == 'task') {
          final today = ref.read(todayProvider);
          final projectId = uri.queryParameters['project'];
          await showNewTaskSheet(
            context,
            dueDate: switch (uri.queryParameters['due']) {
              'tomorrow' => Dates.addDays(today, 1),
              'none' => null,
              // A task for a project has no date unless one is asked for.
              null when projectId != null => null,
              _ => today,
            },
            projectId: ref.read(projectsByIdProvider).containsKey(projectId) ? projectId : null,
          );
        }
      case 'project':
        final id = uri.pathSegments.firstOrNull;
        router.go(Routes.projects);
        final project = ref.read(projectsByIdProvider)[id];
        if (project == null) return;
        await _afterFrame();
        final context = rootNavigatorKey.currentContext;
        if (context != null && context.mounted) await showProjectEditor(context, project: project);
    }
  }

  /// Waits for the route change to mount and for the app to be fully in the
  /// foreground. A link usually arrives while iOS is still activating the app,
  /// and a sheet opened then can't take keyboard focus.
  static Future<void> _afterFrame() async {
    final binding = WidgetsBinding.instance;
    if (binding.lifecycleState != AppLifecycleState.resumed) {
      final resumed = Completer<void>();
      final listener = AppLifecycleListener(onResume: resumed.complete);
      await resumed.future.timeout(const Duration(seconds: 2), onTimeout: () {});
      listener.dispose();
    }
    // Two frames: one for the route change, one for the new page to mount.
    await binding.endOfFrame;
    await binding.endOfFrame;
  }
}
