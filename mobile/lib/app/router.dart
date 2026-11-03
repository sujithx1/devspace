import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/home/home_screen.dart';
import '../features/more/more_screen.dart';
import '../features/notes/notes_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/projects/projects_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/tasks/task_detail_screen.dart';
import '../features/tasks/tasks_screen.dart';
import '../features/workspaces/workspace_detail_screen.dart';
import '../features/workspaces/workspaces_screen.dart';
import 'providers/workspace_providers.dart';
import 'shell/app_shell.dart';

abstract final class Routes {
  static const welcome = '/welcome';
  static const home = '/home';
  static const tasks = '/tasks';
  static const projects = '/projects';
  static const notes = '/notes';
  static const more = '/more';
  static const workspaces = '/more/workspaces';
  static const settings = '/more/settings';

  static String workspace(String id) => '/more/workspaces/$id';
}

/// Task detail, reachable from each tab that lists tasks so Back stays in that tab.
GoRoute _taskRoute() => GoRoute(
  path: 'task/:taskId',
  pageBuilder: (c, s) => _page(s, TaskDetailScreen(taskId: s.pathParameters['taskId']!)),
);

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

Page<void> _page(GoRouterState state, Widget child, {String? title}) =>
    CupertinoPage<void>(key: state.pageKey, title: title, child: child);

Page<void> _fade(GoRouterState state, Widget child) => CustomTransitionPage<void>(
  key: state.pageKey,
  child: child,
  transitionDuration: const Duration(milliseconds: 380),
  transitionsBuilder: (context, animation, _, child) =>
      FadeTransition(opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut), child: child),
);

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(workspacesProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.home,
    refreshListenable: refresh,
    redirect: (context, state) {
      final hasWorkspace = ref.read(workspacesProvider).value?.isNotEmpty ?? false;
      final onWelcome = state.matchedLocation == Routes.welcome;
      if (!hasWorkspace) return onWelcome ? null : Routes.welcome;
      if (onWelcome) return Routes.home;
      return null;
    },
    routes: [
      GoRoute(path: Routes.welcome, pageBuilder: (context, state) => _fade(state, const OnboardingScreen())),
      StatefulShellRoute.indexedStack(
        pageBuilder: (context, state, shell) => _fade(state, AppShell(shell: shell)),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.home,
                pageBuilder: (c, s) => _page(s, const HomeScreen(), title: 'Home'),
                routes: [_taskRoute()],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.tasks,
                pageBuilder: (c, s) => _page(s, const TasksScreen(), title: 'Tasks'),
                routes: [_taskRoute()],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.projects,
                pageBuilder: (c, s) => _page(s, const ProjectsScreen(), title: 'Projects'),
                routes: [_taskRoute()],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.notes, pageBuilder: (c, s) => _page(s, const NotesScreen(), title: 'Notes'))],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.more,
                pageBuilder: (c, s) => _page(s, const MoreScreen(), title: 'More'),
                routes: [
                  GoRoute(
                    path: 'workspaces',
                    pageBuilder: (c, s) => _page(s, const WorkspacesScreen(), title: 'Workspaces'),
                    routes: [
                      GoRoute(
                        path: ':workspaceId',
                        pageBuilder: (c, s) => _page(s, WorkspaceDetailScreen(workspaceId: s.pathParameters['workspaceId']!)),
                      ),
                    ],
                  ),
                  GoRoute(path: 'settings', pageBuilder: (c, s) => _page(s, const SettingsScreen(), title: 'Settings')),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
