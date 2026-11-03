import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/task_providers.dart';
import '../../app/theme/app_theme.dart';
import '../../core/services/haptics.dart';
import '../../core/widgets/widgets.dart';
import 'task_editor_sheet.dart';
import 'task_logic.dart';
import 'widgets/kanban_board.dart';
import 'widgets/task_filter_sheet.dart';
import 'widgets/task_tile.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  TaskView _view = TaskView.today;
  TaskSort _sort = TaskSort.smart;
  TaskFilter _filter = const TaskFilter();
  bool _board = false;
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _openFilters() async {
    final result = await showTaskFilterSheet(context, sort: _sort, filter: _filter);
    if (result != null) {
      setState(() {
        _sort = result.sort;
        _filter = result.filter;
      });
    }
  }

  void _newTask() {
    final today = ref.read(todayProvider);
    showNewTaskSheet(context, dueDate: !_board && _view == TaskView.today ? today : null);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tasksAsync = ref.watch(tasksProvider);
    final tasks = tasksAsync.value ?? const [];
    final projects = ref.watch(projectsByIdProvider);
    final today = ref.watch(todayProvider);
    final searching = _filter.query.trim().isNotEmpty || _filter.isActive;

    final List<Widget> body;
    if (tasksAsync.isLoading && !tasksAsync.hasValue) {
      body = const [SliverFillRemaining(child: Center(child: CupertinoActivityIndicator()))];
    } else if (_board) {
      body = [
        SliverFillRemaining(
          hasScrollBody: true,
          child: KanbanBoard(columns: boardColumns(tasks, filter: _filter, sort: _sort, projects: projects)),
        ),
      ];
    } else {
      final sections = buildSections(tasks, _view, today, filter: _filter, sort: _sort, projects: projects);
      body = sections.isEmpty
          ? [SliverFillRemaining(hasScrollBody: false, child: _empty(searching))]
          : [for (final s in sections) TaskGroupSliver(title: s.title, tasks: s.tasks, warning: s.isWarning)];
    }

    return DSPage(
      title: 'Tasks',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DSNavIconButton(
            icon: _board ? CupertinoIcons.list_bullet : CupertinoIcons.square_split_2x1,
            semanticLabel: _board ? 'Show list' : 'Show board',
            onPressed: () {
              Haptics.selection();
              setState(() => _board = !_board);
            },
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              DSNavIconButton(
                icon: CupertinoIcons.line_horizontal_3_decrease_circle,
                semanticLabel: 'Sort and filter',
                onPressed: _openFilters,
              ),
              if (_filter.isActive)
                Positioned(
                  right: 8,
                  top: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: colors.accent, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
          DSNavIconButton(icon: CupertinoIcons.plus, semanticLabel: 'New task', onPressed: _newTask),
        ],
      ),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(DSSpacing.page, DSSpacing.xxs, DSSpacing.page, DSSpacing.md),
            child: Column(
              children: [
                CupertinoSearchTextField(
                  controller: _search,
                  placeholder: 'Search tasks',
                  onChanged: (q) => setState(() => _filter = _filter.copyWith(query: q)),
                ),
                if (!_board) ...[
                  const SizedBox(height: DSSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoSlidingSegmentedControl<TaskView>(
                      groupValue: _view,
                      backgroundColor: colors.fill,
                      thumbColor: context.isDark ? colors.fillStrong : colors.surface,
                      onValueChanged: (v) {
                        if (v == null) return;
                        Haptics.selection();
                        setState(() => _view = v);
                      },
                      children: {
                        for (final v in TaskView.values)
                          v: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(v.label, style: context.type.footnote.copyWith(fontWeight: FontWeight.w600)),
                          ),
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        ...body,
      ],
    );
  }

  Widget _empty(bool searching) {
    if (searching) {
      return const DSEmptyState(
        icon: CupertinoIcons.search,
        title: 'No matching tasks',
        message: 'Try a different search, or clear the filters.',
      );
    }
    final (icon, title, message) = switch (_view) {
      TaskView.today => (CupertinoIcons.sun_max, 'Nothing due today', 'Enjoy the calm, or plan something for today.'),
      TaskView.upcoming => (CupertinoIcons.calendar, 'Nothing scheduled', 'Tasks with a future due date show up here.'),
      TaskView.all => (CupertinoIcons.checkmark_circle, 'No open tasks', 'Add a task to get started.'),
      TaskView.completed => (CupertinoIcons.checkmark_seal, 'Nothing completed yet', 'Tasks you finish are kept here.'),
    };
    return DSEmptyState(
      icon: icon,
      title: title,
      message: message,
      actionLabel: _view == TaskView.completed ? null : 'New Task',
      onAction: _view == TaskView.completed ? null : _newTask,
    );
  }
}
