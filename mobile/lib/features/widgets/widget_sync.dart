import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/core_providers.dart';
import '../../app/providers/task_providers.dart';
import '../../app/providers/workspace_providers.dart';
import '../../core/models/enums.dart';
import '../../core/services/widget_bridge.dart';
import 'deep_links.dart';
import 'widget_snapshot.dart';

final widgetBridgeProvider = Provider<WidgetBridge>((ref) => WidgetBridge());

/// Keeps the Home Screen widgets in step with the app, both ways:
///
/// - Whenever tasks, projects, the active workspace or the date change, a fresh
///   snapshot is written to the App Group and WidgetKit is asked to reload.
/// - Actions queued outside the app (a task ticked on a widget, a widget tap,
///   a Shortcut) are applied on launch, on resume and as they arrive.
///
/// Watch this once from the app root to keep it alive.
final widgetSyncProvider = Provider<void>((ref) {
  final bridge = ref.watch(widgetBridgeProvider);
  if (!bridge.isSupported) return;

  Timer? debounce;
  Future<void> publish() async {
    final tasks = ref.read(tasksProvider).value;
    final projects = ref.read(projectsProvider).value;
    if (tasks == null || projects == null) return;
    await bridge.saveSnapshot(
      buildWidgetSnapshot(
        workspace: ref.read(activeWorkspaceProvider),
        tasks: tasks,
        projects: projects,
        now: DateTime.now(),
      ),
    );
    await bridge.reloadWidgets();
  }

  void schedule() {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 300), () => publish().ignore());
  }

  ref.listen(tasksProvider, (_, _) => schedule(), fireImmediately: true);
  ref.listen(projectsProvider, (_, _) => schedule());
  ref.listen(activeWorkspaceProvider, (_, _) => schedule());
  ref.listen(todayProvider, (_, _) => schedule());

  var draining = false;
  Future<void> drain() async {
    if (draining) return;
    draining = true;
    try {
      for (final action in await bridge.takeActions()) {
        switch (action) {
          case CompleteTaskAction(:final taskId, :final completed):
            final task = await ref.read(taskRepositoryProvider).get(taskId);
            if (task == null || task.isCompleted == completed) continue;
            await ref.read(taskServiceProvider).setStatus(task, completed ? TaskStatus.completed : TaskStatus.todo);
          case OpenUrlAction(:final uri):
            await DeepLinks.handle(uri, ref);
        }
      }
    } finally {
      draining = false;
    }
    // The widget may show an optimistic state; replace it with the truth.
    schedule();
  }

  bridge.listen(() => drain().ignore());
  final lifecycle = AppLifecycleListener(onResume: () => drain().ignore());
  // Wait for the first frame so links can navigate.
  WidgetsBinding.instance.addPostFrameCallback((_) => drain().ignore());

  ref.onDispose(() {
    debounce?.cancel();
    lifecycle.dispose();
    bridge.stopListening();
  });
});
