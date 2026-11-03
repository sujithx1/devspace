import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/core_providers.dart';
import '../../app/providers/workspace_providers.dart';
import '../../app/theme/app_theme.dart';
import '../../core/errors/app_exception.dart';
import '../../core/models/enums.dart';
import '../../core/models/task.dart';
import '../../core/services/haptics.dart';
import '../../core/utils/dates.dart';
import '../../core/widgets/widgets.dart';
import 'widgets/task_properties.dart';

/// Quick task creation. [dueDate], [status] and [projectId] pre-fill the
/// draft from wherever the sheet was opened (e.g. Today, a board column).
Future<Task?> showNewTaskSheet(
  BuildContext context, {
  DateTime? dueDate,
  TaskStatus status = TaskStatus.todo,
  String? projectId,
}) {
  return showDSSheet<Task>(
    context,
    builder: (context, controller) => _NewTaskSheet(
      scrollController: controller,
      dueDate: dueDate,
      status: status,
      projectId: projectId,
    ),
  );
}

class _NewTaskSheet extends ConsumerStatefulWidget {
  const _NewTaskSheet({required this.scrollController, this.dueDate, required this.status, this.projectId});

  final ScrollController scrollController;
  final DateTime? dueDate;
  final TaskStatus status;
  final String? projectId;

  @override
  ConsumerState<_NewTaskSheet> createState() => _NewTaskSheetState();
}

class _NewTaskSheetState extends ConsumerState<_NewTaskSheet> {
  final _title = TextEditingController();
  final _notes = TextEditingController();
  final _titleFocus = FocusNode();
  late Task _draft = Task(
    id: '',
    workspaceId: ref.read(activeWorkspaceProvider)!.id,
    title: '',
    status: widget.status,
    dueDate: widget.dueDate == null ? null : Dates.toIso(widget.dueDate!),
    projectId: widget.projectId,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
  String? _error;
  bool _busy = false;
  bool _focusScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Focus after the sheet finishes sliding up, or the focus is dropped.
    final animation = ModalRoute.of(context)?.animation;
    if (animation == null || _focusScheduled) return;
    _focusScheduled = true;
    void listener(AnimationStatus status) {
      if (status != AnimationStatus.completed) return;
      animation.removeStatusListener(listener);
      if (mounted) _titleFocus.requestFocus();
    }

    animation.isCompleted ? _titleFocus.requestFocus() : animation.addStatusListener(listener);
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final d = _draft;
      final task = await ref
          .read(taskRepositoryProvider)
          .create(
            workspaceId: d.workspaceId,
            title: _title.text,
            description: _notes.text,
            status: d.status,
            priority: d.priority,
            dueDate: d.dueDate,
            dueTime: d.dueTime,
            recurrence: d.recurrence,
            tags: d.tags,
            projectId: d.projectId,
          );
      Haptics.success();
      if (mounted) Navigator.of(context).pop(task);
    } on ValidationException catch (e) {
      Haptics.warning();
      setState(() => _error = e.message);
    } catch (e) {
      if (mounted) DSToast.error(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    return ValueListenableBuilder(
      valueListenable: _title,
      builder: (context, value, _) => DSSheetScaffold(
        title: 'New Task',
        doneLabel: 'Add',
        scrollController: widget.scrollController,
        busy: _busy,
        onDone: value.text.trim().isEmpty ? null : _create,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DSSpacing.page),
            child: Container(
              decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(DSRadius.md)),
              padding: const EdgeInsets.fromLTRB(DSSpacing.md, DSSpacing.sm, DSSpacing.md, DSSpacing.xs),
              child: Column(
                children: [
                  CupertinoTextField.borderless(
                    controller: _title,
                    focusNode: _titleFocus,
                    placeholder: 'What needs doing?',
                    style: type.title3,
                    placeholderStyle: type.title3.copyWith(color: colors.textTertiary),
                    padding: EdgeInsets.zero,
                    maxLength: 200,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                    onSubmitted: (v) {
                      if (v.trim().isNotEmpty) _create();
                    },
                  ),
                  const SizedBox(height: DSSpacing.sm),
                  CupertinoTextField.borderless(
                    controller: _notes,
                    placeholder: 'Notes',
                    style: type.callout.copyWith(color: colors.textSecondary),
                    placeholderStyle: type.callout.copyWith(color: colors.textTertiary),
                    padding: const EdgeInsets.only(bottom: DSSpacing.xs),
                    minLines: 1,
                    maxLines: 6,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ],
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(DSSpacing.page + DSSpacing.xxs, DSSpacing.xs, DSSpacing.page, 0),
              child: Text(_error!, style: type.footnote.copyWith(color: colors.danger)),
            ),
          const SizedBox(height: DSSpacing.xl),
          TaskPropertiesSection(task: _draft, onChanged: (t) => setState(() => _draft = t)),
        ],
      ),
    );
  }
}
