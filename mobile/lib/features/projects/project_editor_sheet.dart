import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/core_providers.dart';
import '../../app/providers/workspace_providers.dart';
import '../../app/theme/app_theme.dart';
import '../../core/errors/app_exception.dart';
import '../../core/models/enums.dart';
import '../../core/models/project.dart';
import '../../core/services/haptics.dart';
import '../../core/utils/dates.dart';
import '../../core/widgets/ds_choice_sheet.dart';
import '../../core/widgets/widgets.dart';
import '../../shared/extensions/date_extensions.dart';
import '../../shared/widgets/date_picker_sheet.dart';
import '../../shared/widgets/entity_visuals.dart';

/// Creates a project in the active workspace, or edits [project].
Future<Project?> showProjectEditor(BuildContext context, {Project? project}) {
  return showDSSheet<Project>(
    context,
    builder: (context, controller) => _ProjectEditor(project: project, scrollController: controller),
  );
}

class _ProjectEditor extends ConsumerStatefulWidget {
  const _ProjectEditor({required this.project, required this.scrollController});

  final Project? project;
  final ScrollController scrollController;

  @override
  ConsumerState<_ProjectEditor> createState() => _ProjectEditorState();
}

class _ProjectEditorState extends ConsumerState<_ProjectEditor> {
  late final _name = TextEditingController(text: widget.project?.name ?? '');
  late final _description = TextEditingController(text: widget.project?.description ?? '');
  late ProjectColor _color = widget.project?.color ?? ProjectColor.indigo;
  late ProjectStatus _status = widget.project?.status ?? ProjectStatus.active;
  late Priority _priority = widget.project?.priority ?? Priority.medium;
  late String? _startDate = widget.project?.startDate;
  late String? _dueDate = widget.project?.dueDate;
  Map<String, String> _errors = const {};
  bool _busy = false;

  bool get _isNew => widget.project == null;

  @override
  void initState() {
    super.initState();
    final p = widget.project;
    if (p != null) {
      ref.read(recentRepositoryProvider).touch(workspaceId: p.workspaceId, type: EntityType.project, entityId: p.id).ignore();
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _errors = const {};
    });
    final repo = ref.read(projectRepositoryProvider);
    try {
      final Project saved;
      if (_isNew) {
        saved = await repo.create(
          workspaceId: ref.read(activeWorkspaceProvider)!.id,
          name: _name.text,
          description: _description.text,
          status: _status,
          priority: _priority,
          color: _color,
          startDate: _startDate,
          dueDate: _dueDate,
        );
      } else {
        saved = await repo.update(
          widget.project!.copyWith(
            name: _name.text,
            description: _description.text,
            status: _status,
            priority: _priority,
            color: _color,
            startDate: _startDate,
            dueDate: _dueDate,
          ),
        );
      }
      Haptics.success();
      if (mounted) Navigator.of(context).pop(saved);
    } on ValidationException catch (e) {
      Haptics.warning();
      setState(() => _errors = e.fieldErrors.isEmpty ? {'name': e.message} : e.fieldErrors);
    } catch (e) {
      if (mounted) DSToast.error(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickDate({required bool start}) async {
    final picked = await showDatePickerSheet(
      context,
      title: start ? 'Start Date' : 'Due Date',
      date: start ? _startDate : _dueDate,
      allowTime: false,
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _startDate = picked.date;
      } else {
        _dueDate = picked.date;
      }
      _errors = const {};
    });
  }

  String _dateLabel(String? iso) => iso == null ? 'None' : Dates.parseIso(iso).mediumDate;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ValueListenableBuilder(
      valueListenable: _name,
      builder: (context, value, _) => DSSheetScaffold(
        title: _isNew ? 'New Project' : 'Edit Project',
        doneLabel: _isNew ? 'Create' : 'Save',
        scrollController: widget.scrollController,
        busy: _busy,
        onDone: value.text.trim().isEmpty ? null : _save,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DSSpacing.page),
            child: DSTextField(
              controller: _name,
              label: 'Name',
              placeholder: 'Project name',
              autofocus: _isNew,
              error: _errors['name'],
              maxLength: 80,
              onChanged: (_) {
                if (_errors.isNotEmpty) setState(() => _errors = const {});
              },
            ),
          ),
          const SizedBox(height: DSSpacing.lg),
          Padding(
            padding: const EdgeInsets.fromLTRB(DSSpacing.page, 0, DSSpacing.page, DSSpacing.xl),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final c in ProjectColor.values)
                  Semantics(
                    button: true,
                    selected: c == _color,
                    label: '${c.name} colour',
                    child: GestureDetector(
                      onTap: () {
                        Haptics.selection();
                        setState(() => _color = c);
                      },
                      child: AnimatedContainer(
                        duration: DSMotion.medium,
                        width: 34,
                        height: 34,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: c == _color ? projectColor(context, c) : Colors.transparent, width: 2),
                        ),
                        child: Container(decoration: BoxDecoration(color: projectColor(context, c), shape: BoxShape.circle)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(DSSpacing.page, 0, DSSpacing.page, DSSpacing.xl),
            child: CupertinoSlidingSegmentedControl<ProjectStatus>(
              groupValue: _status,
              backgroundColor: colors.fill,
              thumbColor: context.isDark ? colors.fillStrong : colors.surface,
              onValueChanged: (v) {
                if (v == null) return;
                Haptics.selection();
                setState(() => _status = v);
              },
              children: {
                for (final s in ProjectStatus.values)
                  s: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(s.label, style: context.type.footnote.copyWith(fontWeight: FontWeight.w600)),
                  ),
              },
            ),
          ),
          DSSection(
            footer: _errors['dueDate'],
            children: [
              DSRow(
                title: 'Priority',
                value: _priority.label,
                showChevron: true,
                onTap: () async {
                  final c = await showDSChoiceSheet<Priority>(
                    context,
                    title: 'Priority',
                    selected: _priority,
                    choices: [
                      for (final p in Priority.values.reversed)
                        DSChoice(value: p, label: p.label, leading: PriorityIcon(priority: p, size: 18)),
                    ],
                  );
                  if (c != null) setState(() => _priority = c.value);
                },
              ),
              DSRow(title: 'Start Date', value: _dateLabel(_startDate), showChevron: true, onTap: () => _pickDate(start: true)),
              DSRow(title: 'Due Date', value: _dateLabel(_dueDate), showChevron: true, onTap: () => _pickDate(start: false)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DSSpacing.page),
            child: CupertinoTextField(
              controller: _description,
              placeholder: 'Description',
              minLines: 3,
              maxLines: 8,
              style: context.type.body,
              placeholderStyle: context.type.body.copyWith(color: colors.textTertiary),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(DSRadius.md)),
            ),
          ),
        ],
      ),
    );
  }
}
