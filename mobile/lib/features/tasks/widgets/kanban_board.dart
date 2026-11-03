import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/task.dart';
import '../../../core/services/haptics.dart';
import '../task_actions.dart';
import '../task_editor_sheet.dart';
import 'task_tile.dart';

/// Status board: one column per status, paged horizontally. Long-press a card
/// and drop it on another column to move it.
class KanbanBoard extends ConsumerStatefulWidget {
  const KanbanBoard({super.key, required this.columns});

  final Map<TaskStatus, List<Task>> columns;

  @override
  ConsumerState<KanbanBoard> createState() => _KanbanBoardState();
}

class _KanbanBoardState extends ConsumerState<KanbanBoard> {
  final _pages = PageController(viewportFraction: 0.86);

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statuses = TaskStatus.values;
    return PageView.builder(
      controller: _pages,
      padEnds: false,
      itemCount: statuses.length,
      itemBuilder: (context, i) => Padding(
        padding: EdgeInsets.only(left: i == 0 ? DSSpacing.page : DSSpacing.xs, right: DSSpacing.xs),
        child: _Column(
          status: statuses[i],
          tasks: widget.columns[statuses[i]] ?? const [],
          onDrop: (task) {
            Haptics.success();
            setTaskStatus(context, ref, task, statuses[i]);
          },
        ),
      ),
    );
  }
}

class _Column extends StatelessWidget {
  const _Column({required this.status, required this.tasks, required this.onDrop});

  final TaskStatus status;
  final List<Task> tasks;
  final ValueChanged<Task> onDrop;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = switch (status) {
      TaskStatus.todo => colors.textSecondary,
      TaskStatus.inProgress => colors.warning,
      TaskStatus.completed => colors.success,
    };
    return DragTarget<Task>(
      onWillAcceptWithDetails: (d) => d.data.status != status,
      onAcceptWithDetails: (d) => onDrop(d.data),
      builder: (context, candidates, _) {
        final hovering = candidates.isNotEmpty;
        return AnimatedContainer(
          duration: DSMotion.fast,
          margin: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + DSSpacing.sm),
          decoration: BoxDecoration(
            color: hovering ? colors.accentSoft : colors.fill,
            borderRadius: BorderRadius.circular(DSRadius.lg),
            border: Border.all(color: hovering ? colors.accent : const Color(0x00000000), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(DSSpacing.md, DSSpacing.sm, DSSpacing.xxs, DSSpacing.xxs),
                child: Row(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
                    const SizedBox(width: DSSpacing.xs),
                    Text(status.label, style: context.type.headline),
                    const SizedBox(width: DSSpacing.xs),
                    Text('${tasks.length}', style: context.type.subheadline.copyWith(color: colors.textTertiary)),
                    const Spacer(),
                    if (status != TaskStatus.completed)
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size.square(kMinInteractiveDimensionCupertino),
                        onPressed: () => showNewTaskSheet(context, status: status),
                        child: Icon(CupertinoIcons.plus, size: 20, color: colors.accent, semanticLabel: 'Add to ${status.label}'),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: tasks.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(DSSpacing.xl),
                          child: Text(
                            hovering ? 'Drop here' : 'No tasks',
                            style: context.type.subheadline.copyWith(color: colors.textTertiary),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(DSSpacing.xs, DSSpacing.xxs, DSSpacing.xs, DSSpacing.md),
                        itemCount: tasks.length,
                        separatorBuilder: (_, _) => const SizedBox(height: DSSpacing.xs),
                        itemBuilder: (context, i) => _DraggableCard(task: tasks[i]),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DraggableCard extends StatelessWidget {
  const _DraggableCard({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Widget card({double elevation = 0}) => Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DSRadius.md),
        boxShadow: [BoxShadow(color: colors.shadow, blurRadius: 2 + elevation, offset: Offset(0, 0.5 + elevation / 3))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DSRadius.md),
        child: TaskTile(task: task, swipeable: false, menuOnLongPress: false),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) => LongPressDraggable<Task>(
        data: task,
        hapticFeedbackOnStart: true,
        feedback: SizedBox(
          width: constraints.maxWidth,
          child: Transform.rotate(angle: -0.03, child: card(elevation: 18)),
        ),
        childWhenDragging: Opacity(opacity: 0.35, child: card()),
        child: card(),
      ),
    );
  }
}
