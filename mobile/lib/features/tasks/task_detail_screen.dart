import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ReorderableListView, Material, MaterialType;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers/core_providers.dart';
import '../../app/providers/task_providers.dart';
import '../../app/theme/app_theme.dart';
import '../../core/models/enums.dart';
import '../../core/models/task.dart';
import '../../core/services/haptics.dart';
import '../../core/widgets/widgets.dart';
import 'task_actions.dart';
import 'widgets/task_checkbox.dart';
import 'widgets/task_properties.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  final _title = TextEditingController();
  final _notes = TextEditingController();
  Timer? _debounce;
  bool _loaded = false;
  bool _deleted = false;
  Task? _last;

  @override
  void dispose() {
    _flushText();
    _debounce?.cancel();
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _flushText);
  }

  /// Saves the title and notes if they differ from what's stored. An empty
  /// title is never saved; the previous title is kept instead.
  void _flushText() {
    _debounce?.cancel();
    final task = _last;
    if (task == null || _deleted) return;
    final title = _title.text.trim();
    final notes = _notes.text;
    if ((title.isEmpty || title == task.title) && notes == task.description) return;
    ref
        .read(taskRepositoryProvider)
        .update(task.copyWith(title: title.isEmpty ? task.title : title, description: notes))
        .ignore();
  }

  Future<void> _save(Task updated) async {
    try {
      await ref.read(taskRepositoryProvider).update(updated);
    } catch (e) {
      if (mounted) DSToast.error(context, e);
    }
  }

  Future<void> _delete(Task task) async {
    _deleted = true;
    await deleteTaskWithUndo(context, ref, task);
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(taskProvider(widget.taskId));
    final task = async.value ?? (_deleted ? _last : null);

    if (task == null) {
      return DSPage(
        title: 'Task',
        largeTitle: false,
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: async.isLoading
                ? const Center(child: CupertinoActivityIndicator())
                : const DSEmptyState(
                    icon: CupertinoIcons.trash,
                    title: 'Task not found',
                    message: 'It may have been deleted.',
                  ),
          ),
        ],
      );
    }

    _last = task;
    if (!_loaded) {
      _loaded = true;
      _title.text = task.title;
      _notes.text = task.description;
      _title.addListener(_onTextChanged);
      _notes.addListener(_onTextChanged);
      ref.read(taskServiceProvider).markOpened(task).ignore();
    }

    final colors = context.colors;
    final type = context.type;

    return DSPage(
      title: '',
      largeTitle: false,
      trailing: DSNavIconButton(
        icon: CupertinoIcons.ellipsis_circle,
        semanticLabel: 'Task actions',
        onPressed: () => showTaskActions(context, ref, task),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(DSSpacing.sm, DSSpacing.md, DSSpacing.page, DSSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TaskCheckbox(
                  status: task.status,
                  priority: task.priority,
                  size: 28,
                  onTap: () => toggleTaskComplete(context, ref, task),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: CupertinoTextField.borderless(
                      controller: _title,
                      style: type.title2.copyWith(
                        color: task.isCompleted ? colors.textSecondary : colors.textPrimary,
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        decorationColor: colors.textTertiary,
                      ),
                      placeholder: 'Title',
                      placeholderStyle: type.title2.copyWith(color: colors.textTertiary),
                      padding: EdgeInsets.zero,
                      minLines: 1,
                      maxLines: 5,
                      maxLength: 200,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _flushText(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(DSSpacing.page, 0, DSSpacing.page, DSSpacing.xl),
            child: CupertinoSlidingSegmentedControl<TaskStatus>(
              groupValue: task.status,
              backgroundColor: colors.fill,
              thumbColor: context.isDark ? colors.fillStrong : colors.surface,
              onValueChanged: (s) {
                if (s == null) return;
                Haptics.selection();
                setTaskStatus(context, ref, task, s);
              },
              children: {
                for (final s in TaskStatus.values)
                  s: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(s.label, style: type.footnote.copyWith(fontWeight: FontWeight.w600)),
                  ),
              },
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(DSSpacing.page, 0, DSSpacing.page, DSSpacing.xl),
            child: CupertinoTextField(
              controller: _notes,
              placeholder: 'Add notes',
              minLines: 3,
              maxLines: null,
              style: type.body,
              placeholderStyle: type.body.copyWith(color: colors.textTertiary),
              padding: const EdgeInsets.all(DSSpacing.md),
              textCapitalization: TextCapitalization.sentences,
              decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(DSRadius.md)),
            ),
          ),
        ),
        SliverToBoxAdapter(child: TaskPropertiesSection(task: task, onChanged: _save)),
        SliverToBoxAdapter(child: _SubtasksSection(task: task)),
        SliverToBoxAdapter(
          child: DSSection(
            footer: _footer(task),
            children: [DSRow(title: 'Delete Task', destructive: true, onTap: () => _delete(task))],
          ),
        ),
      ],
    );
  }

  String _footer(Task task) {
    final f = DateFormat.yMMMd().add_jm();
    return [
      'Created ${f.format(task.createdAt)}',
      if (task.completedAt != null) 'Completed ${f.format(task.completedAt!)}',
    ].join('\n');
  }
}

class _SubtasksSection extends ConsumerStatefulWidget {
  const _SubtasksSection({required this.task});

  final Task task;

  @override
  ConsumerState<_SubtasksSection> createState() => _SubtasksSectionState();
}

class _SubtasksSectionState extends ConsumerState<_SubtasksSection> {
  final _input = TextEditingController();
  final _inputFocus = FocusNode();
  List<Subtask>? _optimisticOrder;

  @override
  void dispose() {
    _input.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final title = _input.text.trim();
    if (title.isEmpty) return;
    _input.clear();
    try {
      await ref.read(taskRepositoryProvider).addSubtask(widget.task.id, title);
      Haptics.selection();
      _inputFocus.requestFocus(); // keep adding
    } catch (e) {
      if (mounted) DSToast.error(context, e);
    }
  }

  Future<void> _rename(Subtask s) async {
    await showDSTextPrompt<void>(
      context,
      title: 'Edit Subtask',
      initialValue: s.title,
      confirmLabel: 'Save',
      onSubmit: (v) => ref.read(taskRepositoryProvider).updateSubtask(s.copyWith(title: v)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    final stored = ref.watch(subtasksProvider(widget.task.id)).value ?? const <Subtask>[];
    final subtasks = _optimisticOrder ?? stored;
    final done = stored.where((s) => s.isDone).length;
    final repo = ref.read(taskRepositoryProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(DSSpacing.page, 0, DSSpacing.page, DSSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(DSSpacing.md, 0, DSSpacing.xxs, DSSpacing.xs),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Subtasks',
                    style: type.footnote.copyWith(color: colors.textSecondary, fontWeight: FontWeight.w500),
                  ),
                ),
                if (stored.isNotEmpty)
                  Text('$done of ${stored.length}', style: type.footnote.copyWith(color: colors.textTertiary)),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(DSRadius.md)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                if (subtasks.isNotEmpty)
                  Material(
                    type: MaterialType.transparency,
                    child: ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      itemCount: subtasks.length,
                      onReorderStart: (_) => Haptics.tap(),
                      onReorderItem: (from, to) {
                        final list = [...subtasks];
                        list.insert(to, list.removeAt(from));
                        setState(() => _optimisticOrder = list);
                        repo.reorderSubtasks([for (final s in list) s.id]).whenComplete(() {
                          if (mounted) setState(() => _optimisticOrder = null);
                        });
                      },
                      itemBuilder: (context, i) {
                        final s = subtasks[i];
                        return DSSwipeable(
                          key: ValueKey(s.id),
                          trailing: [
                            DSSwipeAction(
                              icon: CupertinoIcons.trash_fill,
                              label: 'Delete',
                              color: colors.danger,
                              onPressed: () => repo.deleteSubtask(s.id),
                            ),
                          ],
                          child: Container(
                            color: colors.surface,
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    TaskCheckbox(
                                      size: 20,
                                      status: s.isDone ? TaskStatus.completed : TaskStatus.todo,
                                      priority: Priority.medium,
                                      onTap: () {
                                        Haptics.selection();
                                        repo.updateSubtask(s.copyWith(isDone: !s.isDone));
                                      },
                                    ),
                                    Expanded(
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () => _rename(s),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: DSSpacing.sm),
                                          child: Text(
                                            s.title,
                                            style: type.body.copyWith(
                                              color: s.isDone ? colors.textTertiary : colors.textPrimary,
                                              decoration: s.isDone ? TextDecoration.lineThrough : null,
                                              decorationColor: colors.textTertiary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    ReorderableDragStartListener(
                                      index: i,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: DSSpacing.md, vertical: DSSpacing.sm),
                                        child: Icon(
                                          CupertinoIcons.line_horizontal_3,
                                          size: 18,
                                          color: colors.textTertiary,
                                          semanticLabel: 'Reorder',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 44),
                                  child: Container(height: 0.5, color: colors.separator),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(DSSpacing.sm),
                      child: Icon(CupertinoIcons.plus, size: 18, color: colors.accent),
                    ),
                    Expanded(
                      child: CupertinoTextField.borderless(
                        controller: _input,
                        focusNode: _inputFocus,
                        placeholder: 'Add subtask',
                        style: type.body,
                        placeholderStyle: type.body.copyWith(color: colors.textTertiary),
                        padding: const EdgeInsets.symmetric(vertical: DSSpacing.sm),
                        textInputAction: TextInputAction.done,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _add(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
