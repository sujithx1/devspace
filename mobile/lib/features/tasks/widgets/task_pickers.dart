import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/task_providers.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/models/enums.dart';
import '../../../core/services/haptics.dart';
import '../../../core/widgets/ds_choice_sheet.dart';
import '../../../core/widgets/widgets.dart';
import '../../../shared/widgets/entity_visuals.dart';
import '../../projects/project_editor_sheet.dart';

/// `(value: x)` distinguishes "chose none" from dismissing the sheet.
typedef Picked<T> = ({T value});

Future<Picked<Priority>?> pickPriority(BuildContext context, Priority current) async {
  final c = await showDSChoiceSheet<Priority>(
    context,
    title: 'Priority',
    selected: current,
    choices: [
      for (final p in Priority.values.reversed)
        DSChoice(value: p, label: p.label, leading: PriorityIcon(priority: p, size: 18)),
    ],
  );
  return c == null ? null : (value: c.value);
}

Future<Picked<Recurrence?>?> pickRecurrence(BuildContext context, Recurrence? current) async {
  final c = await showDSChoiceSheet<Recurrence?>(
    context,
    title: 'Repeat',
    selected: current,
    footer: 'When you complete a repeating task, the next one is scheduled automatically.',
    choices: [
      const DSChoice(value: null, label: 'Never'),
      for (final r in Recurrence.values) DSChoice(value: r, label: r.label),
    ],
  );
  return c == null ? null : (value: c.value);
}

Future<Picked<String?>?> pickProject(BuildContext context, WidgetRef ref, String? current) async {
  const newProject = '__new__';
  final projects = ref.read(projectsProvider).value ?? const [];
  final open = projects.where((p) => p.status != ProjectStatus.completed || p.id == current);
  final c = await showDSChoiceSheet<String?>(
    context,
    title: 'Project',
    selected: current,
    choices: [
      DSChoice(
        value: null,
        label: 'No Project',
        leading: Icon(CupertinoIcons.tray, size: 20, color: context.colors.textTertiary),
      ),
      for (final p in open)
        DSChoice(
          value: p.id,
          label: p.name,
          subtitle: p.taskCount == 0 ? null : '${p.openTaskCount} open',
          leading: ProjectDot(color: p.color, size: 12),
        ),
      DSChoice(
        value: newProject,
        label: 'New Project…',
        leading: Icon(CupertinoIcons.plus_circle_fill, size: 22, color: context.colors.accent),
      ),
    ],
  );
  if (c == null) return null;
  if (c.value != newProject) return (value: c.value);
  final created = await showProjectEditor(rootNavigatorKey.currentContext!);
  return created == null ? null : (value: created.id);
}

/// Edits a tag list in a bottom sheet with suggestions from the workspace.
Future<List<String>?> editTags(BuildContext context, List<String> current) {
  return showDSBottomSheet<List<String>>(context, builder: (_) => _TagEditor(initial: current));
}

class _TagEditor extends ConsumerStatefulWidget {
  const _TagEditor({required this.initial});

  final List<String> initial;

  @override
  ConsumerState<_TagEditor> createState() => _TagEditorState();
}

class _TagEditorState extends ConsumerState<_TagEditor> {
  late final List<String> _tags = [...widget.initial];
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _add(String raw) {
    final tag = raw.trim().replaceFirst(RegExp(r'^#'), '');
    if (tag.isEmpty) return;
    if (!_tags.any((t) => t.toLowerCase() == tag.toLowerCase()) && _tags.length < 20) {
      Haptics.selection();
      setState(() => _tags.add(tag.length > 32 ? tag.substring(0, 32) : tag));
    }
    _input.clear();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final suggestions = ref
        .watch(taskTagsProvider)
        .where((t) => !_tags.any((x) => x.toLowerCase() == t.toLowerCase()))
        .take(12)
        .toList();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: DSSpacing.page),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Tags', style: context.type.title3)),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      _add(_input.text);
                      Navigator.pop(context, _tags);
                    },
                    child: Text('Done', style: context.type.headline.copyWith(color: colors.accent)),
                  ),
                ],
              ),
              const SizedBox(height: DSSpacing.sm),
              CupertinoTextField(
                controller: _input,
                autofocus: true,
                placeholder: 'Add a tag',
                prefix: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text('#', style: context.type.body.copyWith(color: colors.textTertiary)),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: _add,
                style: context.type.body,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                decoration: BoxDecoration(color: colors.fill, borderRadius: BorderRadius.circular(DSRadius.md)),
              ),
              const SizedBox(height: DSSpacing.md),
              if (_tags.isNotEmpty)
                Wrap(
                  spacing: DSSpacing.xs,
                  runSpacing: DSSpacing.xs,
                  children: [
                    for (final t in _tags)
                      TagChip(
                        label: t,
                        selected: true,
                        trailing: CupertinoIcons.xmark,
                        onTap: () => setState(() => _tags.remove(t)),
                      ),
                  ],
                ),
              if (suggestions.isNotEmpty) ...[
                const SizedBox(height: DSSpacing.lg),
                Text('Suggestions', style: context.type.footnote.copyWith(color: colors.textSecondary)),
                const SizedBox(height: DSSpacing.xs),
                Wrap(
                  spacing: DSSpacing.xs,
                  runSpacing: DSSpacing.xs,
                  children: [for (final t in suggestions) TagChip(label: t, trailing: CupertinoIcons.plus, onTap: () => _add(t))],
                ),
              ],
              const SizedBox(height: DSSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class TagChip extends StatelessWidget {
  const TagChip({super.key, required this.label, this.selected = false, this.trailing, this.onTap});

  final String label;
  final bool selected;
  final IconData? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DSPressable(
      onPressed: onTap,
      semanticLabel: 'Tag $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? colors.accentSoft : colors.fill,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '#$label',
              style: context.type.footnote.copyWith(
                color: selected ? colors.accent : colors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 4),
              Icon(trailing, size: 12, color: selected ? colors.accent : colors.textSecondary),
            ],
          ],
        ),
      ),
    );
  }
}
