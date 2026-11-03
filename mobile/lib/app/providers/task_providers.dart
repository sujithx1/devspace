import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/project.dart';
import '../../core/models/recent_visit.dart';
import '../../core/models/task.dart';
import '../../core/utils/dates.dart';
import 'core_providers.dart';
import 'workspace_providers.dart';

final _activeWorkspaceIdOnly = Provider<String?>((ref) => ref.watch(activeWorkspaceProvider.select((w) => w?.id)));

/// Every task in the active workspace.
final tasksProvider = StreamProvider<List<Task>>((ref) {
  final id = ref.watch(_activeWorkspaceIdOnly);
  if (id == null) return Stream.value(const []);
  return ref.watch(taskRepositoryProvider).watchByWorkspace(id);
});

final taskProvider = StreamProvider.family<Task?, String>(
  (ref, id) => ref.watch(taskRepositoryProvider).watch(id),
);

final subtasksProvider = StreamProvider.family<List<Subtask>, String>(
  (ref, taskId) => ref.watch(taskRepositoryProvider).watchSubtasks(taskId),
);

/// Every project in the active workspace.
final projectsProvider = StreamProvider<List<Project>>((ref) {
  final id = ref.watch(_activeWorkspaceIdOnly);
  if (id == null) return Stream.value(const []);
  return ref.watch(projectRepositoryProvider).watchByWorkspace(id);
});

final projectsByIdProvider = Provider<Map<String, Project>>(
  (ref) => {for (final p in ref.watch(projectsProvider).value ?? const <Project>[]) p.id: p},
);

/// Every tag used in the active workspace, most used first.
final taskTagsProvider = Provider<List<String>>((ref) {
  final counts = <String, int>{};
  for (final t in ref.watch(tasksProvider).value ?? const <Task>[]) {
    for (final tag in t.tags) {
      counts[tag] = (counts[tag] ?? 0) + 1;
    }
  }
  return counts.keys.toList()..sort((a, b) => counts[b]!.compareTo(counts[a]!));
});

final recentVisitsProvider = StreamProvider<List<RecentVisit>>((ref) {
  final id = ref.watch(_activeWorkspaceIdOnly);
  if (id == null) return Stream.value(const []);
  return ref.watch(recentRepositoryProvider).watchByWorkspace(id, limit: 8);
});

/// Today's date. Rolls over at midnight and when the app returns to the
/// foreground, so Today and Overdue never go stale.
final todayProvider = NotifierProvider<TodayNotifier, DateTime>(TodayNotifier.new);

class TodayNotifier extends Notifier<DateTime> {
  Timer? _timer;
  AppLifecycleListener? _lifecycle;

  @override
  DateTime build() {
    _lifecycle ??= AppLifecycleListener(onResume: _refresh);
    ref.onDispose(() {
      _timer?.cancel();
      _lifecycle?.dispose();
    });
    _schedule();
    return Dates.dateOnly(DateTime.now());
  }

  void _schedule() {
    _timer?.cancel();
    final now = DateTime.now();
    final midnight = Dates.addDays(Dates.dateOnly(now), 1);
    _timer = Timer(midnight.difference(now) + const Duration(seconds: 1), _refresh);
  }

  void _refresh() {
    final today = Dates.dateOnly(DateTime.now());
    if (today != state) state = today;
    _schedule();
  }
}
