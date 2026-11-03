import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/core_providers.dart';
import '../../app/providers/task_providers.dart';
import '../../core/models/enums.dart';
import '../../core/models/task.dart';
import '../../core/services/haptics.dart';
import '../../core/utils/dates.dart';
import '../../core/widgets/widgets.dart';
import 'task_logic.dart';

/// Opens a task's detail screen inside the current tab, so Back returns to
/// wherever the user came from.
void openTask(BuildContext context, String taskId) {
  final router = GoRouter.of(context);
  final path = router.routerDelegate.currentConfiguration.uri.path;
  const tabs = ['/home', '/tasks', '/projects'];
  final base = tabs.firstWhere((t) => path.startsWith(t), orElse: () => '/tasks');
  router.push('$base/task/$taskId');
}

Future<void> setTaskStatus(BuildContext context, WidgetRef ref, Task task, TaskStatus status) async {
  if (status == TaskStatus.completed) Haptics.success();
  try {
    final next = await ref.read(taskServiceProvider).setStatus(task, status);
    if (next != null && context.mounted) {
      DSToast.show(
        context,
        'Next “${next.title}”: ${dueLabel(next, ref.read(todayProvider))}',
        tone: DSToastTone.success,
      );
    }
  } catch (e) {
    if (context.mounted) DSToast.error(context, e);
  }
}

Future<void> toggleTaskComplete(BuildContext context, WidgetRef ref, Task task) =>
    setTaskStatus(context, ref, task, task.isCompleted ? TaskStatus.todo : TaskStatus.completed);

/// Deletes [task] straight away and offers Undo.
Future<void> deleteTaskWithUndo(BuildContext context, WidgetRef ref, Task task) async {
  Haptics.warning();
  final service = ref.read(taskServiceProvider);
  try {
    final snapshot = await service.delete(task.id);
    if (snapshot == null || !context.mounted) return;
    DSToast.show(
      context,
      'Deleted “${task.title}”',
      actionLabel: 'Undo',
      onAction: () => service.undoDelete(snapshot),
    );
  } catch (e) {
    if (context.mounted) DSToast.error(context, e);
  }
}

Future<void> rescheduleTask(BuildContext context, WidgetRef ref, Task task, DateTime? day) async {
  Haptics.selection();
  try {
    await ref.read(taskRepositoryProvider).update(task.copyWith(dueDate: day == null ? null : Dates.toIso(day)));
  } catch (e) {
    if (context.mounted) DSToast.error(context, e);
  }
}

enum _TaskMenu { start, stop, complete, reopen, today, tomorrow, delete }

/// Long-press menu for a task row.
Future<void> showTaskActions(BuildContext context, WidgetRef ref, Task task) async {
  Haptics.tap();
  final today = ref.read(todayProvider);
  final action = await showDSActionSheet<_TaskMenu>(
    context,
    title: task.title,
    actions: [
      if (task.status == TaskStatus.todo) const DSSheetAction(label: 'Start', value: _TaskMenu.start),
      if (task.status == TaskStatus.inProgress) const DSSheetAction(label: 'Move to To Do', value: _TaskMenu.stop),
      if (task.isOpen) const DSSheetAction(label: 'Complete', value: _TaskMenu.complete),
      if (task.isCompleted) const DSSheetAction(label: 'Mark as Not Done', value: _TaskMenu.reopen),
      if (task.isOpen && !task.isDueOn(today)) const DSSheetAction(label: 'Do Today', value: _TaskMenu.today),
      if (task.isOpen) const DSSheetAction(label: 'Do Tomorrow', value: _TaskMenu.tomorrow),
      const DSSheetAction(label: 'Delete Task', value: _TaskMenu.delete, destructive: true),
    ],
  );
  if (action == null || !context.mounted) return;
  switch (action) {
    case _TaskMenu.start:
      await setTaskStatus(context, ref, task, TaskStatus.inProgress);
    case _TaskMenu.stop:
    case _TaskMenu.reopen:
      await setTaskStatus(context, ref, task, TaskStatus.todo);
    case _TaskMenu.complete:
      await setTaskStatus(context, ref, task, TaskStatus.completed);
    case _TaskMenu.today:
      await rescheduleTask(context, ref, task, today);
    case _TaskMenu.tomorrow:
      await rescheduleTask(context, ref, task, Dates.addDays(today, 1));
    case _TaskMenu.delete:
      await deleteTaskWithUndo(context, ref, task);
  }
}
