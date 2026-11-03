import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/task_providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/task.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/widgets.dart';
import '../../../shared/widgets/entity_visuals.dart';
import '../task_actions.dart';
import '../task_logic.dart';
import 'task_checkbox.dart';

/// One task in a list: checkbox, title and a quiet line of details.
/// Swipe right to complete, left to delete; long-press for more.
class TaskTile extends ConsumerStatefulWidget {
  const TaskTile({super.key, required this.task, this.showProject = true, this.swipeable = true, this.menuOnLongPress = true});

  final Task task;
  final bool showProject;

  /// Off inside horizontally scrolling containers like the board.
  final bool swipeable;

  /// Off where long-press is used for dragging.
  final bool menuOnLongPress;

  @override
  ConsumerState<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends ConsumerState<TaskTile> {
  /// Shows the tick for a moment before the task leaves the list.
  bool _completing = false;
  Timer? _commit;

  @override
  void dispose() {
    _commit?.cancel();
    super.dispose();
  }

  void _toggle() {
    final task = widget.task;
    if (task.isCompleted) {
      toggleTaskComplete(context, ref, task);
      return;
    }
    if (_completing) {
      // Second tap within the grace period cancels.
      _commit?.cancel();
      setState(() => _completing = false);
      return;
    }
    setState(() => _completing = true);
    _commit = Timer(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      toggleTaskComplete(context, ref, task);
    });
  }

  @override
  void didUpdateWidget(TaskTile old) {
    super.didUpdateWidget(old);
    if (old.task.status != widget.task.status) _completing = false;
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final colors = context.colors;
    final type = context.type;
    final today = ref.watch(todayProvider);
    final project = widget.showProject && task.projectId != null ? ref.watch(projectsByIdProvider)[task.projectId] : null;
    final done = task.isCompleted || _completing;
    final overdue = task.isOverdue(today);

    final meta = <Widget>[
      if (task.dueDate != null)
        _Meta(
          icon: CupertinoIcons.calendar,
          label: dueLabel(task, today),
          color: overdue ? colors.danger : (task.isDueOn(today) ? colors.accent : colors.textSecondary),
        ),
      if (task.recurrence != null) Icon(CupertinoIcons.repeat, size: 12, color: colors.textSecondary),
      if (project != null)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ProjectDot(color: project.color, size: 7),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Text(
                project.name,
                style: type.footnote.copyWith(color: colors.textSecondary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      if (task.subtaskCount > 0)
        _Meta(icon: CupertinoIcons.checkmark_square, label: '${task.subtasksDone}/${task.subtaskCount}', color: colors.textSecondary),
      if (task.description.isNotEmpty) Icon(CupertinoIcons.text_alignleft, size: 12, color: colors.textTertiary),
      for (final tag in task.tags.take(2)) Text('#$tag', style: type.footnote.copyWith(color: colors.textTertiary)),
    ];

    final content = Container(
      color: colors.surface,
      padding: const EdgeInsets.fromLTRB(DSSpacing.xs, DSSpacing.xxs, DSSpacing.md, DSSpacing.xxs),
      constraints: const BoxConstraints(minHeight: 52),
      child: Row(
        children: [
          TaskCheckbox(
            status: _completing ? TaskStatus.completed : task.status,
            priority: task.priority,
            onTap: _toggle,
          ),
          const SizedBox(width: DSSpacing.xxs),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: DSSpacing.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: DSMotion.medium,
                    style: type.body.copyWith(
                      color: done ? colors.textTertiary : colors.textPrimary,
                      decoration: done ? TextDecoration.lineThrough : TextDecoration.none,
                      decorationColor: colors.textTertiary,
                    ),
                    child: Text(task.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Wrap(spacing: DSSpacing.sm, runSpacing: 2, crossAxisAlignment: WrapCrossAlignment.center, children: meta),
                  ],
                ],
              ),
            ),
          ),
          if (task.isOpen && task.priority.rank >= Priority.high.rank)
            Padding(
              padding: const EdgeInsets.only(left: DSSpacing.xs),
              child: PriorityIcon(priority: task.priority, size: 14),
            ),
        ],
      ),
    );

    final tappable = Semantics(
      button: true,
      hint: swipeHint,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => openTask(context, task.id),
        onLongPress: widget.menuOnLongPress ? () => showTaskActions(context, ref, task) : null,
        child: content,
      ),
    );
    if (!widget.swipeable) return tappable;

    return DSSwipeable(
      leading: [
        DSSwipeAction(
          icon: task.isCompleted ? CupertinoIcons.arrow_uturn_left : CupertinoIcons.checkmark_alt,
          label: task.isCompleted ? 'Undo' : 'Done',
          color: task.isCompleted ? colors.textSecondary : colors.success,
          onPressed: () => toggleTaskComplete(context, ref, task),
        ),
      ],
      trailing: [
        DSSwipeAction(
          icon: CupertinoIcons.trash_fill,
          label: 'Delete',
          color: colors.danger,
          onPressed: () => deleteTaskWithUndo(context, ref, task),
        ),
        if (task.isOpen)
          DSSwipeAction(
            icon: CupertinoIcons.sunrise_fill,
            label: 'Tomorrow',
            color: colors.warning,
            onPressed: () => rescheduleTask(context, ref, task, Dates.addDays(ref.read(todayProvider), 1)),
          ),
      ],
      child: tappable,
    );
  }

  String? get swipeHint => widget.swipeable ? 'Swipe right to complete, left for more' : null;
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 3),
      Text(label, style: context.type.footnote.copyWith(color: color)),
    ],
  );
}

/// A titled, rounded group of task rows as a sliver, built lazily.
class TaskGroupSliver extends StatelessWidget {
  const TaskGroupSliver({super.key, required this.title, required this.tasks, this.warning = false, this.showProject = true, this.trailing});

  final String title;
  final List<Task> tasks;
  final bool warning;
  final bool showProject;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(DSSpacing.page + DSSpacing.md, 0, DSSpacing.page, DSSpacing.xs),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: context.type.footnote.copyWith(
                        color: warning ? colors.danger : colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                trailing ?? Text('${tasks.length}', style: context.type.footnote.copyWith(color: colors.textTertiary)),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(DSSpacing.page, 0, DSSpacing.page, DSSpacing.xl),
          sliver: DecoratedSliver(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(DSRadius.md),
              border: context.isDark ? Border.all(color: colors.border, width: 0.5) : null,
              boxShadow: context.isDark ? null : [BoxShadow(color: colors.shadow, blurRadius: 2, offset: const Offset(0, 0.5))],
            ),
            sliver: SliverList.separated(
              itemCount: tasks.length,
              separatorBuilder: (_, _) => Padding(
                padding: const EdgeInsets.only(left: 48),
                child: Container(height: 0.5, color: colors.separator),
              ),
              itemBuilder: (context, i) => ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(i == 0 ? DSRadius.md : 0),
                  bottom: Radius.circular(i == tasks.length - 1 ? DSRadius.md : 0),
                ),
                child: TaskTile(key: ValueKey(tasks[i].id), task: tasks[i], showProject: showProject),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
