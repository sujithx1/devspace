import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/task_providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/models/enums.dart';
import '../../../core/services/haptics.dart';
import '../../../core/widgets/ds_choice_sheet.dart';
import '../../../core/widgets/widgets.dart';
import '../../../shared/widgets/entity_visuals.dart';
import '../task_logic.dart';

typedef SortAndFilter = ({TaskSort sort, TaskFilter filter});

Future<SortAndFilter?> showTaskFilterSheet(BuildContext context, {required TaskSort sort, required TaskFilter filter}) {
  return showDSBottomSheet<SortAndFilter>(context, builder: (_) => _FilterSheet(sort: sort, filter: filter));
}

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet({required this.sort, required this.filter});

  final TaskSort sort;
  final TaskFilter filter;

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late TaskSort _sort = widget.sort;
  late TaskFilter _filter = widget.filter;

  void _apply() => Navigator.pop<SortAndFilter>(context, (sort: _sort, filter: _filter));

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final projects = ref.watch(projectsProvider).value ?? const [];
    final tags = ref.watch(taskTagsProvider);
    final projectName = switch (_filter.projectId) {
      null => 'Any',
      TaskFilter.noProject => 'No Project',
      final id => projects.where((p) => p.id == id).firstOrNull?.name ?? 'Any',
    };
    Widget check(bool on) => AnimatedOpacity(
      opacity: on ? 1 : 0,
      duration: DSMotion.fast,
      child: Icon(CupertinoIcons.checkmark_alt, color: colors.accent, size: 22),
    );

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(DSSpacing.page + DSSpacing.xxs, 0, DSSpacing.page, DSSpacing.sm),
                child: Row(
                  children: [
                    Expanded(child: Text('Sort & Filter', style: context.type.title3)),
                    if (_filter.isActive || _sort != TaskSort.smart)
                      CupertinoButton(
                        padding: const EdgeInsets.only(right: DSSpacing.md),
                        onPressed: () => setState(() {
                          _sort = TaskSort.smart;
                          _filter = TaskFilter(query: _filter.query);
                        }),
                        child: Text('Reset', style: context.type.body.copyWith(color: colors.danger)),
                      ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _apply,
                      child: Text('Done', style: context.type.headline.copyWith(color: colors.accent)),
                    ),
                  ],
                ),
              ),
              DSSection(
                header: 'Sort By',
                children: [
                  for (final s in TaskSort.values)
                    DSRow(
                      title: s.label,
                      subtitle: s == TaskSort.smart ? 'In progress first, then due date and priority' : null,
                      trailing: check(s == _sort),
                      onTap: () {
                        Haptics.selection();
                        setState(() => _sort = s);
                      },
                    ),
                ],
              ),
              DSSection(
                header: 'Priority',
                dividerIndent: DSRow.iconIndent,
                children: [
                  for (final p in Priority.values.reversed)
                    DSRow(
                      leading: SizedBox(width: DSIconBadge.size, child: Center(child: PriorityIcon(priority: p, size: 18))),
                      title: p.label,
                      trailing: check(_filter.priorities.contains(p)),
                      onTap: () {
                        Haptics.selection();
                        final next = {..._filter.priorities};
                        next.contains(p) ? next.remove(p) : next.add(p);
                        setState(() => _filter = _filter.copyWith(priorities: next));
                      },
                    ),
                ],
              ),
              DSSection(
                children: [
                  DSRow(
                    title: 'Project',
                    value: projectName,
                    showChevron: true,
                    onTap: () async {
                      final c = await showDSChoiceSheet<String?>(
                        context,
                        title: 'Project',
                        selected: _filter.projectId,
                        choices: [
                          const DSChoice(value: null, label: 'Any Project'),
                          const DSChoice(value: TaskFilter.noProject, label: 'No Project'),
                          for (final p in projects)
                            DSChoice(value: p.id, label: p.name, leading: ProjectDot(color: p.color, size: 12)),
                        ],
                      );
                      if (c != null) setState(() => _filter = _filter.copyWith(projectId: () => c.value));
                    },
                  ),
                  DSRow(
                    title: 'Tag',
                    value: _filter.tag == null ? 'Any' : '#${_filter.tag}',
                    showChevron: true,
                    enabled: tags.isNotEmpty || _filter.tag != null,
                    onTap: () async {
                      final c = await showDSChoiceSheet<String?>(
                        context,
                        title: 'Tag',
                        selected: _filter.tag,
                        choices: [
                          const DSChoice(value: null, label: 'Any Tag'),
                          for (final t in tags) DSChoice(value: t, label: '#$t'),
                        ],
                      );
                      if (c != null) setState(() => _filter = _filter.copyWith(tag: () => c.value));
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
