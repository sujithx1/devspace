import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/providers/preferences_providers.dart';
import '../../app/providers/task_providers.dart';
import '../../app/providers/workspace_providers.dart';
import '../../app/theme/app_theme.dart';
import '../../core/models/enums.dart';
import '../../core/models/project.dart';
import '../../core/models/task.dart';
import '../../core/utils/dates.dart';
import '../../core/widgets/widgets.dart';
import '../../shared/extensions/date_extensions.dart';
import '../../shared/widgets/entity_visuals.dart';
import '../projects/project_editor_sheet.dart';
import '../tasks/task_actions.dart';
import '../tasks/task_editor_sheet.dart';
import '../tasks/task_logic.dart';
import '../tasks/widgets/task_tile.dart';
import '../workspaces/workspace_switcher_sheet.dart';

/// Today at a glance: what's overdue and due, what's coming up, and the
/// projects in motion. Sections only appear when they have something to say.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _maxRows = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final today = ref.watch(todayProvider);
    final tasks = ref.watch(tasksProvider).value ?? const <Task>[];
    final projects = ref.watch(projectsProvider).value ?? const <Project>[];
    final stats = TaskStats.from(tasks, today);

    final open = tasks.where((t) => t.isOpen);
    final overdue = sortTasks(open.where((t) => t.isOverdue(today)), TaskSort.smart);
    final dueToday = sortTasks(open.where((t) => t.isDueOn(today)), TaskSort.smart);
    final activeProjects = projects.where((p) => p.status == ProjectStatus.active).toList()
      ..sort((a, b) => (a.dueDate ?? '9999').compareTo(b.dueDate ?? '9999'));
    final isEmpty = tasks.isEmpty && projects.isEmpty;

    void seeAllTasks() => StatefulNavigationShell.maybeOf(context)?.goBranch(1);

    return Scaffold(
      backgroundColor: colors.background,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          SliverPersistentHeader(pinned: true, delegate: _StatusBarScrim(MediaQuery.paddingOf(context).top, colors.background)),
          const SliverToBoxAdapter(child: _Header()),
          const SliverToBoxAdapter(child: _QuickActions()),
          if (isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Align(
                alignment: Alignment(0, -0.5),
                child: DSEmptyState(
                  icon: CupertinoIcons.sun_max,
                  title: 'A clear day',
                  message: 'Add a task or a project and your day will start to take shape here.',
                ),
              ),
            )
          else ...[
            if (tasks.isNotEmpty) SliverToBoxAdapter(child: _ProgressCard(stats: stats)),
            if (overdue.isNotEmpty)
              TaskGroupSliver(
                title: 'Overdue',
                warning: true,
                tasks: overdue.take(_maxRows).toList(),
                trailing: overdue.length > _maxRows ? _SeeAll(count: overdue.length, onTap: seeAllTasks) : null,
              ),
            if (dueToday.isNotEmpty)
              TaskGroupSliver(
                title: 'Today',
                tasks: dueToday.take(_maxRows).toList(),
                trailing: dueToday.length > _maxRows ? _SeeAll(count: dueToday.length, onTap: seeAllTasks) : null,
              )
            else if (overdue.isEmpty && tasks.isNotEmpty)
              SliverToBoxAdapter(
                child: DSSection(
                  header: 'Today',
                  children: [
                    DSRow(
                      leading: Icon(CupertinoIcons.checkmark_seal_fill, color: colors.success, size: 24),
                      title: 'Nothing due today',
                      subtitle: stats.completedToday > 0 ? 'You finished ${stats.completedToday} already.' : null,
                    ),
                  ],
                ),
              ),
            SliverToBoxAdapter(child: _UpcomingDeadlines(tasks: tasks, projects: projects, today: today)),
            if (activeProjects.isNotEmpty) SliverToBoxAdapter(child: _ActiveProjects(projects: activeProjects.take(4).toList())),
            const SliverToBoxAdapter(child: _RecentlyOpened()),
          ],
          SliverToBoxAdapter(child: SizedBox(height: MediaQuery.paddingOf(context).bottom + DSSpacing.lg)),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final type = context.type;
    final workspace = ref.watch(activeWorkspaceProvider);
    final name = ref.watch(displayNameProvider).value ?? '';
    ref.watch(todayProvider); // re-greet after midnight
    final now = DateTime.now();
    final greeting = name.isEmpty ? now.greeting : '${now.greeting}, ${name.split(' ').first}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(DSSpacing.page, DSSpacing.xs, DSSpacing.page, DSSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (workspace != null)
            DSPressable(
              onPressed: () => showWorkspaceSwitcher(context),
              semanticLabel: 'Workspace ${workspace.name}. Switch workspace',
              child: Container(
                padding: const EdgeInsets.fromLTRB(6, 5, 10, 5),
                decoration: BoxDecoration(color: colors.fill, borderRadius: BorderRadius.circular(999)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(workspace.icon, style: const TextStyle(fontSize: 15)),
                    const SizedBox(width: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: Text(
                        workspace.name,
                        style: type.subheadline.copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(CupertinoIcons.chevron_down, size: 12, color: colors.textSecondary),
                  ],
                ),
              ),
            ),
          const SizedBox(height: DSSpacing.xl),
          Text(
            now.longWeekdayDate.toUpperCase(),
            style: type.footnote.copyWith(color: colors.accent, fontWeight: FontWeight.w600, letterSpacing: 0.4),
          ),
          const SizedBox(height: DSSpacing.xxs),
          Semantics(header: true, child: Text(greeting, style: type.largeTitle)),
        ],
      ),
    );
  }
}

class _QuickActions extends ConsumerWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(DSSpacing.page, 0, DSSpacing.page, DSSpacing.xl),
      child: Row(
        children: [
          Expanded(
            child: DSButton(
              label: 'New Task',
              icon: CupertinoIcons.checkmark_circle_fill,
              variant: DSButtonVariant.tinted,
              size: DSButtonSize.medium,
              expand: true,
              onPressed: () => showNewTaskSheet(context, dueDate: ref.read(todayProvider)),
            ),
          ),
          const SizedBox(width: DSSpacing.sm),
          Expanded(
            child: DSButton(
              label: 'New Project',
              icon: CupertinoIcons.square_stack_3d_up_fill,
              variant: DSButtonVariant.tinted,
              size: DSButtonSize.medium,
              expand: true,
              onPressed: () => showProjectEditor(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// Today's progress ring plus this week's completions, Monday to Sunday.
class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.stats});

  final TaskStats stats;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    final todayTotal = stats.completedToday + stats.dueToday + stats.overdue;
    final peak = stats.dailyCompletions.fold<int>(1, (a, b) => b > a ? b : a);
    final todayIndex = DateTime.now().weekday - 1;
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(DSSpacing.page, 0, DSSpacing.page, DSSpacing.xl),
      child: Container(
        padding: const EdgeInsets.all(DSSpacing.md),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(DSRadius.lg),
          border: context.isDark ? Border.all(color: colors.border, width: 0.5) : null,
          boxShadow: context.isDark ? null : [BoxShadow(color: colors.shadow, blurRadius: 2, offset: const Offset(0, 0.5))],
        ),
        child: Row(
          children: [
            ProgressRing(
              progress: stats.todayProgress,
              color: colors.accent,
              size: 56,
              stroke: 6,
              child: Text(
                '${(stats.todayProgress * 100).round()}%',
                textScaler: TextScaler.noScaling,
                style: type.caption.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: DSSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    todayTotal == 0 ? 'No tasks due today' : '${stats.completedToday} of $todayTotal done today',
                    style: type.headline,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      '${stats.open} open',
                      if (stats.overdue > 0) '${stats.overdue} overdue',
                      '${stats.completedThisWeek} done this week',
                    ].join(' · '),
                    style: type.footnote.copyWith(color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: DSSpacing.sm),
            Semantics(
              label: 'Completed per day this week: ${stats.dailyCompletions.join(', ')}',
              excludeSemantics: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < 7; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(end: stats.dailyCompletions[i] / peak),
                            duration: DSMotion.slow,
                            curve: DSMotion.standard,
                            builder: (context, v, _) => Container(
                              width: 6,
                              height: 4 + 28 * v,
                              decoration: BoxDecoration(
                                color: i == todayIndex ? colors.accent : colors.accent.withValues(alpha: i < todayIndex ? 0.35 : 0.12),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            days[i],
                            textScaler: TextScaler.noScaling,
                            style: type.caption2.copyWith(
                              color: i == todayIndex ? colors.accent : colors.textTertiary,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Task and project deadlines in the coming week, soonest first.
class _UpcomingDeadlines extends ConsumerWidget {
  const _UpcomingDeadlines({required this.tasks, required this.projects, required this.today});

  final List<Task> tasks;
  final List<Project> projects;
  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final horizon = Dates.addDays(today, 7);
    bool inWindow(DateTime? d) => d != null && d.isAfter(today) && !d.isAfter(horizon);

    final items = <({DateTime day, Widget row})>[
      for (final t in tasks.where((t) => t.isOpen && inWindow(t.dueDay)))
        (
          day: t.dueAt!,
          row: DSRow(
            leading: _DateBadge(day: t.dueDay!),
            title: t.title,
            subtitle: dueLabel(t, today),
            trailing: t.priority.rank >= Priority.high.rank ? PriorityIcon(priority: t.priority, size: 14) : null,
            onTap: () => openTask(context, t.id),
          ),
        ),
      for (final p in projects.where((p) => p.status != ProjectStatus.completed && inWindow(p.dueDay)))
        (
          day: p.dueDay!,
          row: DSRow(
            leading: _DateBadge(day: p.dueDay!, color: projectColor(context, p.color)),
            title: p.name,
            subtitle: 'Project deadline · ${dayHeading(p.dueDay!, today)}',
            onTap: () => showProjectEditor(context, project: p),
          ),
        ),
    ]..sort((a, b) => a.day.compareTo(b.day));

    if (items.isEmpty) return const SizedBox.shrink();
    return DSSection(
      header: 'Coming Up',
      dividerIndent: DSRow.iconIndent + 6,
      footer: items.length > 6 ? '${items.length - 6} more in the next 7 days' : null,
      headerTrailing: Icon(CupertinoIcons.calendar, size: 14, color: colors.textTertiary),
      children: [for (final i in items.take(6)) i.row],
    );
  }
}

class _DateBadge extends StatelessWidget {
  const _DateBadge({required this.day, this.color});

  final DateTime day;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tint = color ?? colors.accent;
    return Container(
      width: 36,
      padding: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(color: tint.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(DSRadius.sm)),
      child: Column(
        children: [
          Text(
            DateFormat('EEE').format(day).toUpperCase(),
            textScaler: TextScaler.noScaling,
            style: context.type.caption2.copyWith(color: tint, fontSize: 9, fontWeight: FontWeight.w700),
          ),
          Text(
            '${day.day}',
            textScaler: TextScaler.noScaling,
            style: context.type.headline.copyWith(color: tint, height: 1.1),
          ),
        ],
      ),
    );
  }
}

class _ActiveProjects extends StatelessWidget {
  const _ActiveProjects({required this.projects});

  final List<Project> projects;

  @override
  Widget build(BuildContext context) {
    return DSSection(
      header: 'Active Projects',
      headerTrailing: _SeeAll(onTap: () => StatefulNavigationShell.maybeOf(context)?.goBranch(2)),
      dividerIndent: DSRow.iconIndent,
      children: [
        for (final p in projects)
          DSRow(
            leading: ProgressRing(progress: p.progress, color: projectColor(context, p.color), size: 28, stroke: 3.5),
            title: p.name,
            subtitle: [
              p.taskCount == 0 ? 'No tasks yet' : '${p.completedTaskCount} of ${p.taskCount} tasks done',
              if (p.dueDay != null) 'Due ${p.dueDay!.mediumDate}',
            ].join(' · '),
            showChevron: true,
            onTap: () => showProjectEditor(context, project: p),
          ),
      ],
    );
  }
}

class _RecentlyOpened extends ConsumerWidget {
  const _RecentlyOpened();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visits = ref.watch(recentVisitsProvider).value ?? const [];
    final tasks = {for (final t in ref.watch(tasksProvider).value ?? const <Task>[]) t.id: t};
    final projects = ref.watch(projectsByIdProvider);
    final colors = context.colors;

    final rows = <Widget>[];
    for (final v in visits) {
      if (v.entityType == EntityType.task && tasks[v.entityId] != null) {
        final t = tasks[v.entityId]!;
        rows.add(
          DSRow(
            leading: SizedBox(
              width: DSIconBadge.size,
              child: Icon(
                t.isCompleted ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                color: t.isCompleted ? colors.accent : colors.textTertiary,
                size: 22,
              ),
            ),
            title: t.title,
            showChevron: true,
            onTap: () => openTask(context, t.id),
          ),
        );
      } else if (v.entityType == EntityType.project && projects[v.entityId] != null) {
        final p = projects[v.entityId]!;
        rows.add(
          DSRow(
            leading: SizedBox(width: DSIconBadge.size, child: Center(child: ProjectDot(color: p.color, size: 12))),
            title: p.name,
            showChevron: true,
            onTap: () => showProjectEditor(context, project: p),
          ),
        );
      }
      if (rows.length == 4) break;
    }
    if (rows.isEmpty) return const SizedBox.shrink();
    return DSSection(header: 'Recently Opened', dividerIndent: DSRow.iconIndent, children: rows);
  }
}

class _SeeAll extends StatelessWidget {
  const _SeeAll({this.count, required this.onTap});

  final int? count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => CupertinoButton(
    padding: EdgeInsets.zero,
    minimumSize: const Size(0, 20),
    onPressed: onTap,
    child: Text(
      count == null ? 'See All' : 'See All $count',
      style: context.type.footnote.copyWith(color: context.colors.accent, fontWeight: FontWeight.w600),
    ),
  );
}

/// Keeps content from scrolling visibly under the status bar on screens
/// without a navigation bar.
class _StatusBarScrim extends SliverPersistentHeaderDelegate {
  _StatusBarScrim(this.height, this.color);

  final double height;
  final Color color;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      SizedBox.expand(child: ColoredBox(color: color.withValues(alpha: 0.94)));

  @override
  bool shouldRebuild(covariant _StatusBarScrim old) => old.height != height || old.color != color;
}
