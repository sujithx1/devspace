import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/core_providers.dart';
import '../../app/providers/task_providers.dart';
import '../../app/theme/app_theme.dart';
import '../../core/models/enums.dart';
import '../../core/models/project.dart';
import '../../core/services/haptics.dart';
import '../../core/widgets/widgets.dart';
import '../../shared/extensions/date_extensions.dart';
import '../../shared/widgets/entity_visuals.dart';
import 'project_editor_sheet.dart';

/// Projects grouped by status with progress from their linked tasks.
/// (The per-project overview arrives with the Projects phase.)
class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  static const _order = [ProjectStatus.active, ProjectStatus.planning, ProjectStatus.onHold, ProjectStatus.completed];

  Future<void> _delete(BuildContext context, WidgetRef ref, Project p) async {
    final ok = await showDSConfirm(
      context,
      title: 'Delete “${p.name}”?',
      message: p.taskCount == 0
          ? 'This can’t be undone.'
          : 'Its ${p.taskCount} task${p.taskCount == 1 ? '' : 's'} will be kept, without a project.',
      confirmLabel: 'Delete',
    );
    if (!ok) return;
    try {
      await ref.read(projectRepositoryProvider).delete(p.id);
      Haptics.success();
    } catch (e) {
      if (context.mounted) DSToast.error(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(projectsProvider);
    final projects = async.value ?? const <Project>[];
    final colors = context.colors;

    return DSPage(
      title: 'Projects',
      trailing: DSNavIconButton(
        icon: CupertinoIcons.plus,
        semanticLabel: 'New project',
        onPressed: () => showProjectEditor(context),
      ),
      slivers: [
        if (async.isLoading && !async.hasValue)
          const SliverFillRemaining(child: Center(child: CupertinoActivityIndicator()))
        else if (projects.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: DSEmptyState(
              icon: CupertinoIcons.square_stack_3d_up,
              title: 'No projects yet',
              message: 'Group related tasks into a project to track progress and deadlines.',
              actionLabel: 'New Project',
              onAction: () => showProjectEditor(context),
            ),
          )
        else ...[
          const SliverToBoxAdapter(child: SizedBox(height: DSSpacing.xs)),
          for (final status in _order)
            if (projects.any((p) => p.status == status))
              SliverToBoxAdapter(
                child: DSSection(
                  header: status.label,
                  dividerIndent: DSRow.iconIndent,
                  children: [
                    for (final p in projects.where((p) => p.status == status))
                      DSSwipeable(
                        key: ValueKey(p.id),
                        trailing: [
                          DSSwipeAction(
                            icon: CupertinoIcons.trash_fill,
                            label: 'Delete',
                            color: colors.danger,
                            onPressed: () => _delete(context, ref, p),
                          ),
                        ],
                        child: DSRow(
                          leading: ProgressRing(
                            progress: p.progress,
                            color: projectColor(context, p.color),
                            size: 28,
                            stroke: 3.5,
                          ),
                          title: p.name,
                          subtitle: [
                            p.taskCount == 0 ? 'No tasks' : '${p.completedTaskCount}/${p.taskCount} tasks',
                            if (p.dueDay != null) 'Due ${p.dueDay!.mediumDate}',
                          ].join(' · '),
                          trailing: p.priority.rank >= Priority.high.rank ? PriorityIcon(priority: p.priority, size: 14) : null,
                          showChevron: true,
                          onTap: () => showProjectEditor(context, project: p),
                          onLongPress: () => _delete(context, ref, p),
                        ),
                      ),
                  ],
                ),
              ),
        ],
      ],
    );
  }
}
